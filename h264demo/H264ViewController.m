//
//  H264ViewController.m
//  h264demo



#import "H264ViewController.h"
#import "VideoDecoder.h"
#import "colorconvert.h"
@interface H264ViewController ()

@end

@implementation H264ViewController
@synthesize btn_start;
@synthesize label_status;
@synthesize VideoView;

int mTrans=0x0F0F0F0F;
-(void)decodeAndShow : (char*) pFrameRGB length:(int)len nWidth:(int)nWidth nHeight:(int)nHeight
{
    
    
    //NSLog(@"decode ret = %d readLen = %d\n", ret, nFrameLen);
    if(len > 0)
    {
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
        CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pFrameRGB, nWidth*nHeight*3,kCFAllocatorNull);
        CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        CGImageRef cgImage = CGImageCreate(nWidth,
                                           nHeight,
                                           8,
                                           24,
                                           nWidth*3,
                                           colorSpace,
                                           bitmapInfo,
                                           provider,
                                           NULL,
                                           YES,
                                           kCGRenderingIntentDefault);
        CGColorSpaceRelease(colorSpace);
        //UIImage *image = [UIImage imageWithCGImage:cgImage];
        UIImage* image = [[UIImage alloc]initWithCGImage:cgImage];   //crespo modify 20111020
        CGImageRelease(cgImage);
        CGDataProviderRelease(provider);
        CFRelease(data);
        [self performSelectorOnMainThread:@selector(updateView:) withObject:image waitUntilDone:YES];
        //[image release];
    }
    
    return;
}

-(void)updateView:(UIImage*)newImage
{
    NSLog(@"显示新画面");
    VideoView.image = newImage;
}
- (void)decode:(id)sender
{
    NSLog(@"start");
    
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSLog(bundlePath);
    //NSString *FilePath = [bundlePath stringByAppendingPathComponent: @"320x240.264"];
    NSString *FilePath = [bundlePath stringByAppendingPathComponent: @"176x144.264"];
    NSLog(FilePath);
    FILE *_imgFileHandle =NULL;
    
    _imgFileHandle =fopen([FilePath UTF8String],"rb");
    
    if (_imgFileHandle != NULL)
    {
        NSLog(@"File Exist");
        X264_H handle = VideoDecoder_Init();
        int iTemp=0;
    	int nalLen;
        int bytesRead = 0;
        int NalBufUsed=0;
    	int SockBufUsed=0;
        
        bool bFirst=true;
    	bool bFindPPS=true;
        
        char  SockBuf[2048];
        char  NalBuf[40980]; // 40k
        char  buffOut[115200];
        char  rgbBuffer[230400];
        int outSize, nWidth, nHeight;
        outSize = 115200;
        memset(SockBuf,0,2048);
        memset(buffOut,0,115200);
        InitConvtTbl();
        do {
            bytesRead = fread(SockBuf, 1, 2048, _imgFileHandle);
            NSLog(@"bytesRead  = %d", bytesRead);
            if (bytesRead<=0) {
                break;
            }
            SockBufUsed = 0;
            while (bytesRead - SockBufUsed > 0) {
                nalLen = MergeBuffer(NalBuf, NalBufUsed, SockBuf, SockBufUsed, bytesRead-SockBufUsed);
    			NalBufUsed += nalLen;
    			SockBufUsed += nalLen;
    			
    			while(mTrans == 1)
    			{
    				mTrans = 0xFFFFFFFF;
                    
    				if(bFirst==true) // the first start flag
    				{
    					bFirst = false;
    				}
    				else  // a complete NAL data, include 0x00000001 trail.
    				{
    					if(bFindPPS==true) // true
    					{
    						if( (NalBuf[4]&0x1F) == 7 )
    						{
    							bFindPPS = false;
    						}
    						else
    						{
    			   				NalBuf[0]=0;
    		    				NalBuf[1]=0;
    		    				NalBuf[2]=0;
    		    				NalBuf[3]=1;
    		    				
    		    				NalBufUsed=4;
    		    				
    							break;
    						}
    					}
    					
    					//	decode nal
    					iTemp = VideoDecoder_Decode(handle, NalBuf, NalBufUsed, buffOut,  outSize, &nWidth, &nHeight);
    					if(iTemp == 0)
    					{
                            i420_to_rgb24(buffOut, rgbBuffer, nWidth, nHeight);
                            flip(rgbBuffer, nWidth, nHeight);
                            [self decodeAndShow:rgbBuffer length:nWidth*nHeight*3 nWidth:nWidth nHeight:nHeight];
    						//nFrameCount++;
    					}
    					else
    					{
    						//Log.e("DecoderNal", "DecoderNal iTemp <= 0");
    					}
                        
    		            //if(iTemp>0)
                        //postInvalidate();  //使用postInvalidate可以直接在线程中更新界面    // postInvalidate();
    				}
                    
    				NalBuf[0]=0;
    				NalBuf[1]=0;
    				NalBuf[2]=0;
    				NalBuf[3]=1;
    				
    				NalBufUsed=4;
    			}
            }
            
            //int nRet = VideoDecoder_Decode(handle, buff, nReadBytes, buffOut,  outSize, &nWidth, &nHeight);
            NSLog(@"nDecodeRet = %d  nWidth = %d  nHeight = %d", iTemp, nWidth, nHeight);
        } while (bytesRead>0);
        
        fclose(_imgFileHandle);
        
    }

}
- (IBAction)start:(id)sender
{
    label_status.text = @"start";
    
    [NSThread detachNewThreadSelector:@selector(decode:) toTarget:self withObject:nil];
    /*
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSLog(bundlePath);
    NSString *FilePath = [bundlePath stringByAppendingPathComponent: @"320x240.264"];
    NSLog(FilePath);
    FILE *_imgFileHandle =NULL;
    
    _imgFileHandle =fopen([FilePath UTF8String],"rb");
    
    if (_imgFileHandle != NULL)
    {
        NSLog(@"File Exist");
        X264_H handle = VideoDecoder_Init();
        int iTemp=0;
    	int nalLen;
        int bytesRead = 0;
        int NalBufUsed=0;
    	int SockBufUsed=0;
        
        bool bFirst=true;
    	bool bFindPPS=true;
        
        char  SockBuf[2048];
        char  NalBuf[40980]; // 40k
        char  buffOut[115200];
        char  rgbBuffer[230400];
        int outSize, nWidth, nHeight;
        outSize = 115200;
        memset(SockBuf,0,2048);
        memset(buffOut,0,115200);
        InitConvtTbl();
        do {
            bytesRead = fread(SockBuf, 1, 2048, _imgFileHandle);
            NSLog(@"bytesRead  = %d", bytesRead);
            if (bytesRead<=0) {
                break;
            }
            SockBufUsed = 0;
            while (bytesRead - SockBufUsed > 0) {
                nalLen = MergeBuffer(NalBuf, NalBufUsed, SockBuf, SockBufUsed, bytesRead-SockBufUsed);
    			NalBufUsed += nalLen;
    			SockBufUsed += nalLen;
    			
    			while(mTrans == 1)
    			{
    				mTrans = 0xFFFFFFFF;
                    
    				if(bFirst==true) // the first start flag
    				{
    					bFirst = false;
    				}
    				else  // a complete NAL data, include 0x00000001 trail.
    				{
    					if(bFindPPS==true) // true
    					{
    						if( (NalBuf[4]&0x1F) == 7 )
    						{
    							bFindPPS = false;
    						}
    						else
    						{
    			   				NalBuf[0]=0;
    		    				NalBuf[1]=0;
    		    				NalBuf[2]=0;
    		    				NalBuf[3]=1;
    		    				
    		    				NalBufUsed=4;
    		    				
    							break;
    						}
    					}
    					
    					//	decode nal
    					iTemp = VideoDecoder_Decode(handle, NalBuf, NalBufUsed, buffOut,  outSize, &nWidth, &nHeight);
    					if(iTemp == 0)
    					{
                            i420_to_rgb24(buffOut, rgbBuffer, nWidth, nHeight);
                            [self decodeAndShow:rgbBuffer length:nWidth*nHeight*3 nWidth:nWidth nHeight:nHeight];
    						//nFrameCount++;
    					}
    					else
    					{
    						//Log.e("DecoderNal", "DecoderNal iTemp <= 0");
    					}
                        
    		            //if(iTemp>0)
                        //postInvalidate();  //使用postInvalidate可以直接在线程中更新界面    // postInvalidate();
    				}
                    
    				NalBuf[0]=0;
    				NalBuf[1]=0;
    				NalBuf[2]=0;
    				NalBuf[3]=1;
    				
    				NalBufUsed=4;
    			}
            }
            
            //int nRet = VideoDecoder_Decode(handle, buff, nReadBytes, buffOut,  outSize, &nWidth, &nHeight);
            NSLog(@"nDecodeRet = %d  nWidth = %d  nHeight = %d", iTemp, nWidth, nHeight);
        } while (bytesRead>0);

        fclose(_imgFileHandle);
        
    }
    */
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

int MergeBuffer(char* NalBuf, int NalBufUsed, char* SockBuf, int SockBufUsed, int SockRemain)
{//把读取的数剧分割成NAL块
    int  i=0;
    char Temp;
    
    for(i=0; i<SockRemain; i++)
    {
        Temp  =SockBuf[i+SockBufUsed];
        NalBuf[i+NalBufUsed]=Temp;
        
        mTrans <<= 8;
        mTrans  |= Temp;
        
        if(mTrans == 1) // 找到一个开始字
        {
            i++;
            break;
        }
    }
    
    return i;
}
void flip(char *pRGBBuffer, int nWidth, int nHeight)
{
    char temp[nWidth*3];
    for (int i = 0; i<nHeight/2; i++) {
        memcpy(temp, pRGBBuffer + i*nWidth*3, nWidth*3);
        memcpy(pRGBBuffer + i*nWidth*3, pRGBBuffer + (nHeight - i - 1)*nWidth*3, nWidth*3);
        memcpy(pRGBBuffer + (nHeight - i - 1)*nWidth*3, temp, nWidth*3);
    }
    /*
    for (int i = 0; i<nHeight/2; i++) {
        memcpy(temp, pRGBBuffer + i*nWidth + nWidth*nHeight, nWidth);
        memcpy(pRGBBuffer + i*nWidth + nWidth*nHeight, pRGBBuffer + (nHeight - i - 1)*nWidth + nWidth*nHeight, nWidth);
        memcpy(pRGBBuffer + (nHeight - i - 1)*nWidth + nWidth*nHeight, temp, nWidth);
    }
    for (int i = 0; i<nHeight/2; i++) {
        memcpy(temp, pRGBBuffer + i*nWidth + nWidth*nHeight*2, nWidth);
        memcpy(pRGBBuffer + i*nWidth + nWidth*nHeight*2, pRGBBuffer + (nHeight - i - 1)*nWidth + nWidth*nHeight*2, nWidth);
        memcpy(pRGBBuffer + (nHeight - i - 1)*nWidth + nWidth*nHeight*2, temp, nWidth);
    }
     */
    
}
@end
