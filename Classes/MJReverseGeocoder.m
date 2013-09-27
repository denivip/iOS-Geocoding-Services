/*
 * MJReverseGeocoder.m
 *
 *
	 Copyright (c) 2011, Mohammed Jisrawi
	 All rights reserved.
	 
	 Redistribution and use in source and binary forms, with or without
	 modification, are permitted provided that the following conditions are met:
	 
	 * Redistributions of source code must retain the above copyright
	   notice, this list of conditions and the following disclaimer.
	 
	 * Redistributions in binary form must reproduce the above copyright
	   notice, this list of conditions and the following disclaimer in the
	   documentation and/or other materials provided with the distribution.
	 
	 * Neither the name of the Mohammed Jisrawi nor the
	   names of its contributors may be used to endorse or promote products
	   derived from this software without specific prior written permission.
	 
	 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
	 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
	 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	 DISCLAIMED. IN NO EVENT SHALL MOHAMMED JISRAWI BE LIABLE FOR ANY
	 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
	 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
	 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
	 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */


#import "MJReverseGeocoder.h"

@interface MJReverseGeocoder ()
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, copy) MJReverseGeocoderCompletionBlock completion;
@end

@implementation MJReverseGeocoder

- (id)initWithCoordinate:(CLLocationCoordinate2D)coord{
	if(self = [[MJReverseGeocoder alloc] init]){
		_coordinate = coord;
	}
	return self;
}

- (void)start
{
    [self startOnCompletion:nil];
}

/*
 *	Opens a URL Connection and calls Google's JSON reverse geocoding service
 */
- (void)startOnCompletion:(MJReverseGeocoderCompletionBlock)completion{
    self.completion = completion;

    //build url string using coordinate
	NSString *urlString = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/geocode/json?latlng=%f,%f&sensor=true",
						   _coordinate.latitude, _coordinate.longitude];
    
    //build request URL
    NSURL *requestURL = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    //build NSURLRequest
    NSURLRequest *geocodingRequest=[NSURLRequest requestWithURL:requestURL
                                                    cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                timeoutInterval:60.0];
    
    //create connection and start downloading data
    NSURLConnection *connection=[[NSURLConnection alloc] initWithRequest:geocodingRequest delegate:self];
    if(connection){
        //connection valid, so init data holder
        _receivedData = [NSMutableData data];
    }else{
        //connection failed, tell delegate
        NSError *error = [NSError errorWithDomain:@"MJGeocoderError" code:5 userInfo:nil];
        [_delegate reverseGeocoder:self didFailWithError:error];
        if (self.completion) {
            self.completion(nil, error);
            self.completion = nil;
        }
    }
}

/*
 *  Reset data when a new response is received
 */
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    [_receivedData setLength:0];
}

/*
 *  Append received data
 */
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [error userInfo][NSURLErrorFailingURLStringErrorKey]);
}

/*
 *  Called when done downloading response from Google. Builds an AddressComponents object
 *	and tells the delegate that it was successful or informs the delegate of a failure.
 */
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSDictionary *resultDict = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:nil];

	NSString *status = [resultDict valueForKey:@"status"];
	if([status isEqualToString:@"OK"]){
		//if successful
		//get first element as array
		NSArray *firstResultAddress = resultDict[@"results"][0][@"address_components"];
		
		Address *resultAddress = [[Address alloc] init];
		resultAddress.streetNumber = [Address addressComponent:@"street_number" inAddressArray:firstResultAddress ofType:@"long_name"];
		resultAddress.route = [Address addressComponent:@"route" inAddressArray:firstResultAddress ofType:@"long_name"];
		resultAddress.city = [Address addressComponent:@"locality" inAddressArray:firstResultAddress ofType:@"long_name"];
		resultAddress.stateCode = [Address addressComponent:@"administrative_area_level_1" inAddressArray:firstResultAddress ofType:@"short_name"];
		resultAddress.postalCode = [Address addressComponent:@"postal_code" inAddressArray:firstResultAddress ofType:@"short_name"];
		resultAddress.countryName = [Address addressComponent:@"country" inAddressArray:firstResultAddress ofType:@"long_name"];
		
		[_delegate reverseGeocoder:self didFindAddress:resultAddress];
        if (self.completion) {
            self.completion(resultAddress, nil);
            self.completion = nil;
        }
	}else{
		//if status code is not OK
		NSError *error = nil;
		
        NSDictionary *userInfo;
		if (status) {
            userInfo = @{ NSLocalizedDescriptionKey : status };
        }

		if([status isEqualToString:@"ZERO_RESULTS"])
		{
			error = [NSError errorWithDomain:@"MJGeocoderError" code:1 userInfo:userInfo];
		}
		else if([status isEqualToString:@"OVER_QUERY_LIMIT"])
		{
			error = [NSError errorWithDomain:@"MJGeocoderError" code:2 userInfo:userInfo];
		}
		else if([status isEqualToString:@"REQUEST_DENIED"])
		{
			error = [NSError errorWithDomain:@"MJGeocoderError" code:3 userInfo:userInfo];
		}
		else if([status isEqualToString:@"INVALID_REQUEST"])
		{
			error = [NSError errorWithDomain:@"MJGeocoderError" code:4 userInfo:userInfo];
		}
		
		[_delegate reverseGeocoder:self didFailWithError:error];
        if (self.completion) {
            self.completion(nil, error);
            self.completion = nil;
        }
	}
}

@end
