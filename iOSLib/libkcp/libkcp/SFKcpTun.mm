//
//  SFKcpTun.m
//  libkcp
//
//  Created by 孔祥波 on 28/04/2017.
//  Copyright © 2017 Kong XiangBo. All rights reserved.
//
#include <unistd.h>
#include <sys/time.h>
#include <cstring>
#include <cstdio>
#include "sess.h"
#import "SFKcpTun.h"
UDPSession *sess;

void
itimeofday(long *sec, long *usec) {
    struct timeval time;
    gettimeofday(&time, NULL);
    if (sec) *sec = time.tv_sec;
    if (usec) *usec = time.tv_usec;
}

IUINT64 iclock64(void) {
    long s, u;
    IUINT64 value;
    itimeofday(&s, &u);
    value = ((IUINT64) s) * 1000 + (u / 1000);
    return value;
}

IUINT32 iclock() {
    return (IUINT32) (iclock64() & 0xfffffffful);
}
@interface SFKcpTun ()
//@property (weak, nonatomic)  UDPSession *sess;
//@property (strong, nonatomic)  UITextField *port;

@end

@implementation SFKcpTun
{
    dispatch_source_t _timer;
    dispatch_queue_t queue ;
    dispatch_queue_t writequeue ;
}
-(instancetype)initWithConfig:(TunConfig *)c ipaddr:(NSString*)ip port:(int)port queue:(dispatch_queue_t)dqueue
{
    if (self = [super init]){
        self.config = c;
        self.server = ip;
        self.port = port;
        self.dispatchqueue = dqueue;
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        writequeue = dispatch_queue_create("com.abigt.kcpwrite", DISPATCH_QUEUE_SERIAL);
        [self startUDPSession];
    }
    return self;
}
-(void)startUDPSession
{
    if (self.config.key.length > 0){
        
        BlockCrypt *block = BlockCrypt::blockWith(self.config.key.bytes, self.config.crypt.UTF8String);
        sess = UDPSession::DialWithOptions(self.server.UTF8String, self.port, self.config.dataShards,self.config.parityShards,block);
    }else {
        sess = UDPSession::DialWithOptions(self.server.UTF8String, self.port, self.config.dataShards,self.config.parityShards);
    }
    
    sess->NoDelay(self.config.nodelay, self.config.interval, self.config.resend, self.config.nc);
    sess->WndSize(self.config.sndwnd, self.config.rcvwnd);
    sess->SetMtu(self.config.mtu);
    sess->SetStreamMode(true);
    sess->SetDSCP(self.config.iptos);
    assert(sess != nullptr);
    self.connected = true;
    [self runTest];
}
-(void)restartUDPSessionWithIpaddr:(NSString*)ip port:(int)port
{
    if (sess != nil) {
        UDPSession::Destroy(sess);
    }
    if (self.config.key.length > 0){
        
        BlockCrypt *block = BlockCrypt::blockWith(self.config.key.bytes, self.config.crypt.UTF8String);
        sess = UDPSession::DialWithOptions(self.server.UTF8String, self.port, self.config.dataShards,self.config.parityShards,block);
    }else {
        sess = UDPSession::DialWithOptions(self.server.UTF8String, self.port, self.config.dataShards,self.config.parityShards);
    }
    
  
    sess->NoDelay(self.config.nodelay, self.config.interval, self.config.resend, self.config.nc);
    sess->WndSize(self.config.sndwnd, self.config.rcvwnd);
    sess->SetMtu(self.config.mtu);
    sess->SetStreamMode(true);
    sess->SetDSCP(self.config.iptos);
    self.connected = true;
    assert(sess != nullptr);
    [self runTest];
}
-(void)shutdownUDPSession
{
    self.connected = false;
    UDPSession::Destroy(sess);

}

-(void)input:(NSData*)data{
    
    assert(sess != nullptr);

    
    dispatch_async(writequeue, ^{
        size_t tosend =  data.length;
        size_t sended = 0 ;
        char *ptr = (char *)data.bytes;

        while (sended < tosend) {
            
            
            size_t sendt = sess->Write(ptr, data.length - sended);
            sended += sendt ;
            ptr += sended;
            NSLog(@"KCPTun sended:%zu, totoal:= %zu",sended,tosend);
            sess->Update(iclock());
        }
    });
  
    //NSLog(@"KCPTun sent %zu",sended);
    
}
-(void)run{
    //
    //
    // Create a dispatch source that'll act as a timer on the concurrent queue
    // You'll need to store this somewhere so you can suspend and remove it later on
   //
    dispatch_source_t dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                                              queue);//dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    
    // Setup params for creation of a recurring timer
    double interval = 33.0;
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, 0);
    uint64_t intervalTime = (int64_t)(interval * NSEC_PER_MSEC);
    dispatch_source_set_timer(dispatchSource, startTime, intervalTime, 0);
    
    // Attach the block you want to run on the timer fire
    __weak  SFKcpTun *weakSelf = self;
    dispatch_source_set_event_handler(dispatchSource, ^{
        // Your code here
        SFKcpTun* strongSelf = weakSelf;
        if (strongSelf) {
            if (sess != nil) {
                
//                @synchronized (self) {
//                    while ([self.sendqueue count] > 0){
//                        NSData *data = [self.sendqueue firstObject];
//                        size_t tosend =  data.length;
//                        size_t sended = 0 ;
//                        char *ptr = (char *)data.bytes;
//                        
//                        while (sended < tosend) {
//                            
//                            
//                            size_t sendt = sess->Write(ptr, data.length - sended);
//                            sended += sendt ;
//                            ptr += sended;
//                            NSLog(@"KCPTun sended:%zu, totoal:= %zu",sended,tosend);
//                            sess->Update(iclock());
//                        }
//                        [self.sendqueue removeObjectAtIndex:0];
//                    }
//                    
//                }
                
                
                
                
                
                
                
                char *buf = (char *) malloc(4096);
                
                memset(buf, 0, 4096);
                ssize_t n = sess->Read(buf, 4096);
                sess->Update(iclock());
                if (n > 0 ){
                    NSData *d = [NSData dataWithBytes:buf length:n];
                    NSLog(@"##### kcp recv  %@\n",d);
                    
                    //dispatch_async(strongSelf.dispatchqueue, ^{
                        [strongSelf.delegate didRecevied:d];
                    //});
                    
                }else {
                    //NSLog(@"##### kcp recv  null\n");
                }
                free(buf);
            }
        }
   
        
    });
    
    // Start the timer
    dispatch_resume(dispatchSource);
    _timer = dispatchSource;
    // ----
    
    // When you want to stop the timer, you need to suspend the source
    //dispatch_suspend(dispatchSource);
    
    // If on iOS5 and/or using MRC, you'll need to release the source too
    //dispatch_release(dispatchSource);
}
-(void)runTest
{   __weak  SFKcpTun *weakSelf = self;
    dispatch_async(self->queue, ^{
        SFKcpTun* strongSelf = weakSelf;
        while (strongSelf.connected) {
            
            
            if (strongSelf) {
                if (sess != nil) {
                    
                    
                    char *buf = (char *) malloc(4096);
                    
                    memset(buf, 0, 4096);
                    ssize_t n = sess->Read(buf, 4096);
                    sess->Update(iclock());
                    
                    if (n > 0 ){
                        //NSData *d = [NSData dataWithBytes:buf length:n];
                        NSMutableData *dx = [NSMutableData dataWithLength:n];
                        char *ptr = (char*)dx.bytes;
                        memcpy(ptr, buf, n);
                        NSLog(@"##### kcp recv  %@\n",dx);
                        
                        dispatch_async(strongSelf.dispatchqueue, ^{
                            [strongSelf.delegate didRecevied:dx];
                        });
                        
                    }else {
                        NSLog(@"##### kcp recv  null\n");
                    }
                    free(buf);
                    usleep(33000);
                }else {
                    break;
                }
            }

        }
    });
}
@end
