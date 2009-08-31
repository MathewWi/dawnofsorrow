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
Trim(0,37790-1)
#KillAudio()
ConvertToRGB32()

miniScreens = last
upperScreen = Crop(0,0,256,192).PointResize(512,384)#.Hq2xResize()
lowerScreen = Crop(0,192,256,192).PointResize(512,384)#.Hq2xResize()

map = upperScreen.LanczosResize(200*2,150*2)#(48,32)

upperScreen.Trim(0,524)+lowerScreen.Trim(525, 25748)+upperScreen.Trim(25749,26060)+lowerScreen.Trim(26061, Framecount-1)
OverlayMap(map, 23869+30, 25562, 60, 0)
mainScreen = last

mainScreen.StackHorizontal(miniScreens)
#LanczosResize(Width/2, Height/2)
ConvertToYV12()
