#import "MagTekUDynamoPlugin.h"

#import "MTSCRA.h"

@interface MagTekUDynamoPlugin ()

@property (strong, nonatomic) MTSCRA* mMagTek;
@property bool mDeviceConnected;
@property bool mDeviceOpened;
@property NSString* mTrackDataListenerCallbackId;
@property NSString* mMac;

@end

@implementation MagTekUDynamoPlugin

- (void)pluginInitialize
{
	self.mMagTek = [[MTSCRA alloc] init];
    self.mMagTek.delegate = self.mMagTek;
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(trackDataReady:)
                                                 name:@"trackDataReadyNotification"
                                               object:nil];
    /*
     [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(devConnStatusChange)
     name:@"devConnectionNotification"
     object:nil];
     */
    NSLog(@"MagTek Plugin initialized");
}

- (void)getDiscoveredPeripherals: (CDVInvokedUrlCommand*) command {
    [self.commandDelegate runInBackground:^{
        NSMutableArray *peripherals = [[NSMutableArray alloc] init];
        for (CBPeripheral *peripheral in [self.mMagTek getDiscoveredPeripherals]){
            [peripherals addObject:[self peripheralToDictionary:peripheral]];
        }
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsMultipart:[peripherals copy]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)startScanningForPeripherals: (CDVInvokedUrlCommand *) command {
    [self.commandDelegate runInBackground:^{
        [self.mMagTek startScanningForPeripherals];
        
    }];
}

- (void)stopScanningForPeripherals: (CDVInvokedUrlCommand *) command {
    [self.commandDelegate runInBackground:^{        
        [self.mMagTek stopScanningForPeripherals];

    }];
}

- (void)isDeviceConnected:(CDVInvokedUrlCommand*)command
{
	CDVPluginResult* pluginResult = nil;
    
	//Make MagTek call to check if device is connected
	if(self.mMagTek != nil) {
		self.mDeviceConnected = [self.mMagTek isDeviceConnected];
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:self.mDeviceConnected];
	}
	else {
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"MagTek Plugin was not properly initialized."];
	}
    
	[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)isDeviceOpened:(CDVInvokedUrlCommand*)command
{
	CDVPluginResult* pluginResult = nil;
    
	//Make MagTek call to check if device is opened
	if(self.mMagTek != nil) {
		self.mDeviceOpened = [self.mMagTek isDeviceOpened];
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:self.mDeviceOpened];
	}
	else {
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"MagTek Plugin was not properly initialized."];
	}
    
	[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)openDevice:(CDVInvokedUrlCommand*)command
{
	CDVPluginResult* pluginResult = nil;
    self.mMac = [command.arguments objectAtIndex:0];
    
	//Open MagTek device to start reading card data
	if(self.mMagTek != nil) {
        if(![self mDeviceOpened]){
            [self.mMagTek setDeviceType:(MAGTEKEDYNAMO)];
            [self.mMagTek setAdress:self.mMac];

            self.mDeviceOpened = [self.mMagTek openDevice];
            if([self.mMagTek isDeviceConnected]) {
                self.mDeviceConnected = true;

            }

            if([self.mMagTek isDeviceOpened]) {
                self.mDeviceOpened = true;
            }
            else {
                self.mDeviceOpened = false;
            }

            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:self.mDeviceOpened];
        }
        else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Reader already open."];
        }
    }
	else {
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"MagTek Plugin was not properly initialized."];
	}
    
	[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSMutableDictionary*)peripheralToDictionary:(CBPeripheral *)peripheral {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:[NSString stringWithFormat:@"%@", [peripheral identifier]] forKey:@"identifier"];
    [dict setObject:[NSString stringWithFormat:@"%@" , [peripheral name]] forKey:@"name"];
    // [dict setObject:[NSString stringWithFormat:@"%ld", [peripheral state]] forKey:@"state"];
    switch ([peripheral state]) {
        case CBPeripheralStateDisconnected:
            [dict setObject:@"disconnected" forKey:@"state"];
            break;
        case CBPeripheralStateConnecting:
            [dict setObject:@"connecting" forKey:@"state"];
            break;
        case CBPeripheralStateConnected:
            [dict setObject:@"connected" forKey:@"state"];
            break;
        case CBPeripheralStateDisconnecting:
            [dict setObject:@"disconnecting" forKey:@"state"];
            break;
        default:
            [dict setObject:@"disconnected" forKey:@"state"];
            
    }
    return dict;
}

- (void)closeDevice:(CDVInvokedUrlCommand*)command
{
	CDVPluginResult* pluginResult = nil;
    
	//Close MagTek device to stop listening to card data and wasting energy
	if(self.mMagTek != nil) {
		self.mDeviceOpened = ![self.mMagTek closeDevice];
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:!self.mDeviceOpened];
	}
	else {
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"MagTek Plugin was not properly initialized."];
	}
    
	[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)listenForEvents:(CDVInvokedUrlCommand*)command
{
	CDVPluginResult* pluginResult = nil;
    
	//Listen for specific events only
	if(self.mMagTek != nil) {
		int i;
		NSString* event;
		UInt32 event_types = 0;
        
		for(i = 0; i < [command.arguments count]; i++) {
			event = [command.arguments objectAtIndex:i];
            
			if([event  isEqual: @"TRANS_EVENT_OK"]) {
				event_types |= TRANS_EVENT_OK;
			}
			if([event  isEqual: @"TRANS_EVENT_ERROR"]) {
				event_types |= TRANS_EVENT_ERROR;
			}
			if([event  isEqual: @"TRANS_EVENT_START"]) {
				event_types |= TRANS_EVENT_START;
			}
		}
        
		[self.mMagTek listenForEvents:event_types];
        
        self.mTrackDataListenerCallbackId = command.callbackId;
	}
	else {
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"MagTek Plugin was not properly initialized."];
		[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
	}
}

- (void)returnData
{
	NSMutableDictionary* data = [NSMutableDictionary dictionaryWithObjectsAndKeys: nil];
    
    if(self.mMagTek != nil)
    {
        [data setObject:[self.mMagTek getResponseType] forKey:@"Response.Type"];
        [data setObject:[self.mMagTek getTrackDecodeStatus] forKey:@"Track.Status"];
        [data setObject:[self.mMagTek getCardStatus] forKey:@"Card.Status"];
        [data setObject:[self.mMagTek getEncryptionStatus] forKey:@"Encryption.Status"];
        [data setObject:[NSString stringWithFormat:@"%ld", [self.mMagTek getBatteryLevel] ] forKey:@"Battery.Level"];
        [data setObject:[NSString stringWithFormat:@"%ld", [self.mMagTek getSwipeCount]] forKey:@"Swipe.Count"];
        [data setObject:[self.mMagTek getCardServiceCode] forKey:@"Card.SvcCode"];
        [data setObject:[NSString stringWithFormat:@"%d", [self.mMagTek getCardPANLength]] forKey:@"Card.PANLength"];
        [data setObject:[self.mMagTek getKSN] forKey:@"KSN"];
        [data setObject:[self.mMagTek getDeviceSerial] forKey:@"Device.SerialNumber"];
        [data setObject:[self.mMagTek getTagValue:TLV_CARDIIN] forKey:@"TLV.CARDIIN"];
        [data setObject:[self.mMagTek getMagTekDeviceSerial] forKey:@"MagTekSN"];
        [data setObject:[self.mMagTek getFirmware] forKey:@"FirmPartNumber"];
        [data setObject:[self.mMagTek getTLVVersion] forKey:@"TLV.Version"];
        [data setObject:[self.mMagTek getDeviceName] forKey:@"DevModelName"];
        [data setObject:[self.mMagTek getCapMSR] forKey:@"MSR.Capability"];
        [data setObject:[self.mMagTek getCapTracks] forKey:@"Tracks.Capability"];
        [data setObject:[self.mMagTek getCapMagStripeEncryption] forKey:@"Encryption.Capability"];

        [data setObject:[self.mMagTek getCardIIN] forKey:@"Card.IIN"];
        [data setObject:[self.mMagTek getCardName] forKey:@"Card.Name"];
        [data setObject:[self.mMagTek getCardLast4] forKey:@"Card.Last4"];
        [data setObject:[self.mMagTek getCardExpDate] forKey:@"Card.ExpDate"];
        [data setObject:[self.mMagTek getCardServiceCode] forKey:@"Card.ServiceCode"];
        [data setObject:[self.mMagTek getTrack1Masked] forKey:@"Track1.Masked"];
        [data setObject:[self.mMagTek getTrack2Masked] forKey:@"Track2.Masked"];
        [data setObject:[self.mMagTek getTrack3Masked] forKey:@"Track3.Masked"];
        [data setObject:[self.mMagTek getTrack1] forKey:@"Track1"];
        [data setObject:[self.mMagTek getTrack2] forKey:@"Track2"];
        [data setObject:[self.mMagTek getTrack3] forKey:@"Track3"];
        [data setObject:[self.mMagTek getMagnePrint] forKey:@"MagnePrint"];
        [data setObject:[self.mMagTek getResponseData] forKey:@"RawResponse"];
        
        [self.mMagTek clearBuffers];
        
        CDVPluginResult* pluginResult = nil;
		pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
		[self.commandDelegate sendPluginResult:pluginResult callbackId:self.mTrackDataListenerCallbackId];
    }
}

- (void)onDataEvent:(id)status
{
#ifdef _DGBPRNT
    NSLog(@"onDataEvent: %i", [status intValue]);
#endif
    
	switch ([status intValue])
    {
        case TRANS_STATUS_OK:
        {
            BOOL bTrackError = NO;
            
            NSString *pstrTrackDecodeStatus = [self.mMagTek getTrackDecodeStatus];
            
            [self returnData];
            
            @try
            {
                if(pstrTrackDecodeStatus)
                {
                    if(pstrTrackDecodeStatus.length >= 6)
                    {
#ifdef _DGBPRNT
                        NSString *pStrTrack1Status = [pstrTrackDecodeStatus substringWithRange:NSMakeRange(0, 2)];
                        NSString *pStrTrack2Status = [pstrTrackDecodeStatus substringWithRange:NSMakeRange(2, 2)];
                        NSString *pStrTrack3Status = [pstrTrackDecodeStatus substringWithRange:NSMakeRange(4, 2)];
                        
                        if(pStrTrack1Status && pStrTrack2Status && pStrTrack3Status)
                        {
                            if([pStrTrack1Status compare:@"01"] == NSOrderedSame)
                            {
                                bTrackError=YES;
                            }
                            
                            if([pStrTrack2Status compare:@"01"] == NSOrderedSame)
                            {
                                bTrackError=YES;
                                
                            }
                            
                            if([pStrTrack3Status compare:@"01"] == NSOrderedSame)
                            {
                                bTrackError=YES;
                                
                            }
                            
                            NSLog(@"Track1.Status=%@",pStrTrack1Status);
                            NSLog(@"Track2.Status=%@",pStrTrack2Status);
                            NSLog(@"Track3.Status=%@",pStrTrack3Status);
                        }
#endif
                    }
                }
                
            }
            @catch(NSException *e)
            {
            }
            
            if(bTrackError == NO)
            {
                //[self closeDevice];
            }
            
            break;
            
        }
        case TRANS_STATUS_START:
            
            /*
             *
             *  NOTE: TRANS_STATUS_START should be used with caution. CPU intensive tasks done after this events and before
             *        TRANS_STATUS_OK may interfere with reader communication.
             *
             */
            break;
            
        case TRANS_STATUS_ERROR:
            
            if(self.mMagTek != NULL)
            {
#ifdef _DGBPRNT
                NSLog(@"TRANS_STATUS_ERROR");
#endif
                //[self updateConnStatus];
            }
            
            break;
            
        default:
            
            break;
    }
}

- (void)trackDataReady:(NSNotification *)notification
{
    NSNumber *status = [[notification userInfo] valueForKey:@"status"];
    
    [self performSelectorOnMainThread:@selector(onDataEvent:)
                           withObject:status
                        waitUntilDone:NO];
}

@end