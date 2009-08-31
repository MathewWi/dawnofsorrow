#Import("libgocha.avs")

AviSource("_.avi").FlipVertical
Trim(0,39148)

miniScreens = last
upperScreen = Crop(0,0,256,192).PointResize(512,384)#.Hq2xResize()
lowerScreen = Crop(0,192,256,192).PointResize(512,384)#.Hq2xResize()

mainScreen = upperScreen.Trim(0,524)+lowerScreen.Trim(525, Framecount-1)
#mainScreen = lowerScreen
mainScreen.StackHorizontal(miniScreens)
ConvertToYV12()
