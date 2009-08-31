#Import("libgocha.avs")

function OverlayMap(clip main, clip map, int start, int end, int "fadeinL", int "fadeoutL")
{
	inL = default(fadeinL, 0)
	outL = default(fadeoutL, 0)
	sx = 56
	#x = (256-200)/2 - 1
	#y = (192-150)/2 - 1
	x = (512-400)/2 - 1
	y = 48

	#map = map.ApplyRange(start, end, "FadeIn", inL, $FF000000)
	#map = map.ApplyRange(start, end, "FadeOut", outL, $FF000000)
	#return main.ApplyRange(start, end, "Overlay", map, x, 0, ShowAlpha(map), 0.8)

	main
	((end-outL) < (start+inL)) ? last : ApplyRange(start+inL, end-outL, "Overlay", map, x, y, ShowAlpha(map), 0.8)

	(inL < 1) ? last : ApplyRange(start, start+inL-1, "Animate", start, start+inL-1, "Overlay",
	\ map, x, y, ShowAlpha(map), 0,
	\ map, x, y, ShowAlpha(map), 0.8)
	(outL < 1) ? last : ApplyRange(end-outL+1, end, "Animate", end-outL+1, end, "Overlay",
	\ map, x, y, ShowAlpha(map), 0.8,
	\ map, x, y, ShowAlpha(map), 0)
	return last
}

#AviSource("z_part1.avi")+AviSource("z_part2.avi")
AviSource("x.avi").ConvertToRGB24.FlipVertical
Trim(0,37790-2)
#KillAudio()
ConvertToRGB32()

miniScreens = last
upperScreen = Crop(0,0,256,192).PointResize(512,384)#.Hq2xResize()
lowerScreen = Crop(0,192,256,192).PointResize(512,384)#.Hq2xResize()

map = upperScreen.LanczosResize(200*2,150*2)#(48,32)

upperScreen.Trim(0,524)+lowerScreen.Trim(525, 25748)+upperScreen.Trim(25749,26060)+lowerScreen.Trim(26061, Framecount-1)
OverlayMap(map, 23869, 25562, 30, 0)
mainScreen = last

niceEnd = AviSource("niceend.avi").Crop(0,0,256,192).Trim(2,7831-2-4).KillAudio

#miniScreensAlt = BlankClip(clip = miniScreens.Crop(0,192,256,192)).StackVertical(miniScreens.Crop(0,0,256,192))
#miniScreensAlt = miniScreens.Crop(0,0,256,192).StackVertical(BlankClip(miniScreens.Crop(0,192,256,192), length = 115, color = $ffffff).KillAudio+ImageSource("infobg.png", 115, Framecount - 1, Framerate, pixel_type = "RGB32").AssumeFPS(FrameRateNumerator, FrameRateDenominator))
infoBG = ImageSource("infobg.png", 0, 27804, Framerate, pixel_type = "RGB32").AssumeFPS(FrameRateNumerator, FrameRateDenominator)+miniScreens.Crop(0,0,256,192).Trim(27805, 29959).KillAudio+niceEnd+miniScreens.Crop(0,0,256,192).Trim(37786-2, Framecount - 1-2).KillAudio
miniScreensAlt = miniScreens.Crop(0,0,256,192).StackVertical(infoBG)
mainScreen.StackHorizontal(miniScreensAlt)
AddBorders(0, 96, 0, 96)
#LanczosResize(512, 384)
#ConvertToYV12()

AudioDub(ImageSource("nicos.png", 0, 3, Framerate, pixel_type = "RGB32").PointResize(768,576), Tone(4/Framerate, 440, 44100, 2, "silence")).AssumeFPS(FrameRateNumerator, FrameRateDenominator)++last
