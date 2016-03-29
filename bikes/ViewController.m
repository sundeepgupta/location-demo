#import "ViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>


@interface ViewController () <MKMapViewDelegate, CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) NSArray *stations;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic) BOOL didZoom;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set ourself as the map view's delegate so we can do things like supply it
    // with a custom annotation view for our bike stations
    // The delegate could also be set via Storyboard
    self.mapView.delegate = self;

    [self setupStationsArray];
    [self addStationAnnotationsToMapView];
    
    [self setupLocationManager];
    
    [self geocodeAnAddress];
}

- (void)setupLocationManager {
    // Create it and set it's delegate to our self.
    // The location manager uses the delegate extensively to relay location
    // information to it.
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    // Generally here you'll want to configure your location manager more.
    // Remember to keep things efficient to optimize batter life. Here are some examples:
    //self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    //self.locationManager.distanceFilter = 50;

    // Location services requires user permission.
    // Remember to add the appropriate keys/values to your Info.plist:
    // NSLocationWhenInUseUsageDescription and/or NSLocationAlwaysUsageDescription
    // The value for those keys is a String explaning why you want those capabilities
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestWhenInUseAuthorization];
    }
}

- (void)setupStationsArray {
    // In a real app, because this data could change, you'd use NSURLSession to download it from:
    // http://www.bikesharetoronto.com/stations/json
    // In this example, we previously saved the json data in a file we added to our bundle.
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"stations" ofType:@"json"];
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    
    NSError *error = nil;
    NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:fileData options:NSJSONReadingMutableContainers error:&error];
    
    if (error) {
        // handle the error
    } else {
        self.stations = dataDictionary[@"stationBeanList"];
    }
}

- (void)addStationAnnotationsToMapView {
    // Loop over our stations array to create, configure and add the annotation to the map view
    
    for (NSDictionary *station in self.stations) {
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([station[@"latitude"] doubleValue], [station[@"longitude"] doubleValue]);
        annotation.coordinate = coordinate;
        annotation.title = station[@"stationName"];
        annotation.subtitle = station[@"statusValue"];
        
        [self.mapView addAnnotation:annotation];
    }
}

- (void)geocodeAnAddress {
    // An example of how you can use a geocoder to do "forward" geocoding
    // You can also do "reverse" geocoding to translate a coordinate into an address
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder geocodeAddressString:@"46 spadina ave, toronto" completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        
        if (error) {
            // handle error
        } else {
            CLPlacemark *placeMark = [placemarks lastObject];
            CLLocation *location = placeMark.location;
            NSString *name = placeMark.name;
            NSLog(@"Geocoded location: %@\nName: %@", location, name);
        }
    }];
}


#pragma mark - MKMapViewDelegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    // Implement this delegate method to provide the map view
    // a custom annotation view if you don't want the default red pins.
    
    // For the user's location, don't supply a custom view, use the default blue dot.
    if (annotation == mapView.userLocation) {
        return nil;
    }
    
    // Just like table/collection views reuse cells, map views reuse annotation views.
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"myAnnotationView"];
    
    // If one isn't avaialble for reuse, create it and configure it with our own image.
    if (!annotationView) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"myAnnotationView"];
        annotationView.image = [UIImage imageNamed:@"Bicycle-Green-icon"];
    }
    
    return annotationView;
}

#pragma mark- CLLocationDelegate 
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    // This gets called when the user provides location services permission.
    
    // If they give permission, start tracking the user's location
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    // This gets called when the location manager determines the the user's location has changed.
    // The `locations` array holds at least one location object. If there are multiple they are
    // ordered in oldest to newest.
    
    // We use this flag to only zoom to the user's location the first time,
    // not every time their location changes.
    if (self.didZoom) {
        return;
    }
    
    // Get the latest location, create a map region and zoom the map view to show it.
    CLLocation *location = [locations lastObject];
    
    CLLocationCoordinate2D coordinate = location.coordinate;
    MKCoordinateSpan span = MKCoordinateSpanMake(0.01, 0.01);
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, span);
    
    [self.mapView setRegion:region animated:YES];
    
    // We could stop tracking the user's location now if wanted
//    [self.locationManager stopUpdatingLocation];
    
    // Don't zoom to their location after this.
    self.didZoom = YES;
}

@end
