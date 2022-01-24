#import <Cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import <MTSCRA/MTSCRA.h>

@interface MagTekUDynamoPlugin : CDVPlugin

- (void)getDiscoveredPeripherals: (CDVInvokedUrlCommand*) command;
- (void)startScanningForPeripherals: (CDVInvokedUrlCommand*) command;
- (void)stopScanningForPeripherals: (CDVInvokedUrlCommand*) command;

- (void)isDeviceConnected: (CDVInvokedUrlCommand*) command;
- (void)isDeviceOpened: (CDVInvokedUrlCommand*) command;
- (void)openDevice: (CDVInvokedUrlCommand*) command;
- (void)closeDevice: (CDVInvokedUrlCommand*) command;

- (void)listenForEvents: (CDVInvokedUrlCommand*) command;

@end