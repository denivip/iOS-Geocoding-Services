/*
 *  Address.m
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


#import "Address.h"


@implementation Address

@synthesize name, fullAddress, streetNumber, route, city, stateCode, postalCode, countryName, coordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)c{
    self = [super init];
    if(self){
        coordinate = c;
    }
    
    return self;
}

/*
 *	Finds an address component of a specific type inside the given address components array
 */
+ (NSString *)addressComponent:(NSString *)component inAddressArray:(NSArray *)array ofType:(NSString *)type{
	int index = [array indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){
        NSArray *types = (NSArray*)obj[@"types"];
        if ([types isKindOfClass:[NSArray class]] && types.count) {
            return [types[0] isEqualToString:component];
        }
        else{
            return NO;
        }
	}];
	
	if(index == NSNotFound) return nil;
	
	return [array[index] valueForKey:type];
}


- (NSString *)subtitle{
	return fullAddress;
}


- (NSString *)title{
	return name;
}


- (void)dealloc{
	[name release];
	[fullAddress release];
	[streetNumber release];
	[route release];
	[city release];
	[stateCode release];
	[postalCode release];
	[countryName release];
	[super dealloc];
}

@end
