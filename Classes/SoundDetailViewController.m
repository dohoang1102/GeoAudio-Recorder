//
//  SoundDetailViewController.m
//  GeoAudio Recorder
//
//  Created by saurb on 3/26/10.
//  Copyright 2010 Arizona State University. All rights reserved.
//

#import "SoundDetailViewController.h"


@implementation SoundDetailViewController
@synthesize audioPlayer;
@synthesize soundURL;
@synthesize responseData;
@synthesize playButton;
@synthesize ffwButton;
@synthesize rewButton;
@synthesize progressBar;
@synthesize currentTime;
@synthesize duration;
@synthesize updateTimer;

- (void)viewDidLoad {
	
	self.duration.adjustsFontSizeToFitWidth = YES;
	self.currentTime.adjustsFontSizeToFitWidth = YES;
	self.progressBar.minimumValue = 0.0;
	updateTimer = nil;
	playBtnBG = [[[UIImage imageNamed:@"play.png"] stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0] retain];
	pauseBtnBG = [[[UIImage imageNamed:@"pause.png"] stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0] retain];
	[playButton setImage:playBtnBG forState:UIControlStateNormal];
	
	
	[self getSoundInfo];
	
    [super viewDidLoad];
	
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
	
	NSString* filePath = [[soundURL stringByReplacingOccurrencesOfString:@".json" withString:@".wav"] retain];
	NSLog(@"audio path %@", filePath);
	NSURL* fileURL = [[[NSURL alloc] initFileURLWithPath:filePath] retain];
	AVAudioPlayer* newPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
	self.audioPlayer = newPlayer;
	[newPlayer release];
	[audioPlayer prepareToPlay];
	[audioPlayer setDelegate:self];
	
	// update player info 
	//TODO: what if file exceeds in minutes?
	self.duration.text = [NSString stringWithFormat:@"%d:%02d", (int)self.audioPlayer.duration / 60, (int)self.audioPlayer.duration % 60, nil];
	self.progressBar.maximumValue = self.audioPlayer.duration;
	
	[super viewWillAppear:animated];
}


- (void)getSoundInfo
{
	responseData = [[NSMutableData data] retain];
	NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:soundURL]];
	[[NSURLConnection alloc] initWithRequest:request delegate:self];
}

#pragma mark -
#pragma mark NSURLConnection methods
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse*)response
{
	[responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData*)data
{
	[responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError*)error
{
	NSLog(@"Connection failed to getting sound: %@", [error description]);
	self.title = @"Error Getting Sound";
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[connection release];
	
	NSString* responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
	NSDictionary* soundInfo = [[responseString JSONValue] retain];
	self.title = [soundInfo valueForKey:@"filename"];
	
	// Set up Map
	MKCoordinateRegion region;
	MKCoordinateSpan span;
	span.latitudeDelta = 0.02;
	span.longitudeDelta = 0.02;
	
	location.latitude = [[soundInfo valueForKey:@"lat"] doubleValue];
	location.longitude = [[soundInfo valueForKey:@"lng"] doubleValue];
	region.span =span;
	region.center = location;
	
	locationAnnotation = [[LocationAnnotation alloc] initWithCoordinate:location];
	locationAnnotation.title = [NSString stringWithFormat:@"%f°,\n%f°", location.latitude, location.longitude];
	[mapView addAnnotation:locationAnnotation];
	[mapView setRegion:region animated:TRUE];
	[mapView regionThatFits:region];
	
}

#pragma mark -
#pragma mark MapView Method
- (MKAnnotationView*)mapView:(MKMapView*)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKPinAnnotationView* annView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"currentloc"];
	annView.pinColor = MKPinAnnotationColorRed;
	annView.animatesDrop = TRUE;
	annView.canShowCallout = YES;
	annView.calloutOffset = CGPointMake(-5.0, 5.0);
	return annView;
}

#pragma mark -
#pragma mark Player Method
- (IBAction)playButtonPressed:(UIButton*)sender
{
	if (self.audioPlayer.playing) {
		[self.playButton setImage:playBtnBG forState:UIControlStateHighlighted];
		[self.playButton setImage:playBtnBG forState:UIControlStateNormal];
		[self.audioPlayer pause];
		self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateCurrentTime) userInfo:self.audioPlayer repeats:YES];
	}
	else {
		[self.playButton setImage:pauseBtnBG forState:UIControlStateHighlighted];
		[self.playButton setImage:pauseBtnBG forState:UIControlStateNormal];
		[self.audioPlayer play];
		[self updateViewForPlayerState];
	}
	
}

// TODO:exceeds minutes?
- (void)updateCurrentTime
{
	self.currentTime.text = [NSString stringWithFormat:@"%d:%02d", (int)self.audioPlayer.currentTime / 60, (int)self.audioPlayer.currentTime % 60, nil];
	self.progressBar.value = self.audioPlayer.currentTime;
}

- (void)updateViewForPlayerState
{
	[self updateCurrentTime];
	
	if (self.updateTimer) {
		[self.updateTimer invalidate];
	}
	
	if (self.audioPlayer.playing) {
		self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateCurrentTime) userInfo:self.audioPlayer repeats:YES];
	}
	else {
		self.updateTimer = nil;
	}
	
	
}

- (IBAction)ffwButtonPressed:(UIButton*)sender
{
	NSTimeInterval time = self.audioPlayer.currentTime;
	time += 3.0;
	if (time > self.audioPlayer.duration) {
		[self.playButton setImage:playBtnBG forState:UIControlStateHighlighted];
		[self.playButton setImage:playBtnBG forState:UIControlStateNormal];
		[self.audioPlayer stop];
		self.progressBar.value = self.audioPlayer.duration;
	}
	else {
		self.audioPlayer.currentTime = time;
		self.progressBar.value = time;
		[self.audioPlayer play];
	}
	
}

- (IBAction)rewButtonPressed:(UIButton*)sender
{
	NSTimeInterval time = self.audioPlayer.currentTime;
	time -= 2.0;
	if (time < 0) {
		[self.playButton setImage:playBtnBG forState:UIControlStateHighlighted];
		[self.playButton setImage:playBtnBG forState:UIControlStateNormal];
		[self.audioPlayer stop];
		self.progressBar.value = 0;
	}
	else {
		self.audioPlayer.currentTime = time;
		self.progressBar.value = time;
		[self.audioPlayer play];
	}
	
}

- (IBAction)progressSliderMoved:(UISlider *)sender
{
	self.audioPlayer.currentTime = sender.value;
	[self updateCurrentTime];
}

#pragma mark -
#pragma mark AVAudioPlayerDelegate Method
- (void) audioPlayerDidFinishPlaying: (AVAudioPlayer *) player
                        successfully: (BOOL) completed {
    if (completed == YES) {
        [self.playButton setImage: playBtnBG forState: UIControlStateNormal];
		[self.audioPlayer setCurrentTime:0.];
    }
}



- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[audioPlayer release];
	[soundURL release];
	[responseData release];
	[playButton release];
	[ffwButton release];
	[rewButton release];
	[progressBar release];
	[currentTime release];
	[duration release];
    [super dealloc];
}


@end