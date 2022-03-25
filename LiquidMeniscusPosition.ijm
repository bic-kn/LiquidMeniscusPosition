// Track the meniscus of a liquid in a channel
// =======================================================
// Copyright 2020 Bioimaging Center, University of Konstanz
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// =======================================================
//
// BioImaging Center, University of Konstanz <bioimaging@uni-konstanz.de>
// Martin Stöckl <martin.stoeckl@uni-konstanz.de>

// This macro identifies the position of a liquid meniscus in a channel over
// a time series of images and plots the position against time.
// The macro works for single channel 16-bit transmitted light images where 
// the meniscus is darker than the background


// Constants, adjust as needed
// The time series must start with the meniscus outside the FOV. 
// Set a START_FRAME where the meniscus is inside the FOV and clearly visible
START_FRAME = 10; 

// Get the necessary information from the image stack, assert correctly assigned dimensions and bit depth
original_image = getTitle();
Stack.getDimensions(width, height, channels, slices, frames);
if (frames == 1) {
	exit("A time series image is required");
}
if (channels > 1) {
	exit("Only single channel images are supported!");
}
if (slices > 1) {
	exit("Only images with a single z-plane are supported!");
}
if (bitDepth() != 16) {
	exit("Only 16-bit images are supported!");	
}
time_interval = Stack.getFrameInterval();
getPixelSize(unit, pixelWidth, pixelHeight);
Stack.getUnits(X, Y, Z, Time, Value);

// Duplicate the first frame (no meniscus visible), serves as a reference for the channel structures, 
// which do not change during the time series
Stack.setFrame(1);
run("Duplicate...", "title=first_frame");	

// Subtract each frame from the channel features in the first frame and
// create a new stack from these images.
selectWindow(original_image);	
setBatchMode(true);
for (f = 1; f <= frames; f++) {
	Stack.setFrame(f);
	run("Duplicate...", "title=image_" + f);	
	run("Invert");
	imageCalculator("Add", "image_" + f,"first_frame");	
	selectWindow(original_image);	
}
close("first_frame");
run("Images to Stack", "name=" + original_image + "_meniscus title=image_");
setBatchMode(false);

// Wait for the user to draw a line along the channel.
Stack.setSlice(frames);
setTool("line");
while (selectionType() != 5) {
	waitForUser("Create a straight line selection along channel!");
}

// For each frame measure the intensity profile along the channel, the brighest point is the 
// meniscus, start from the START_FRAME with a visible meniscus, 
// store the position of the most prominent intensity maximum.
maxima_list = newArray(frames);

for (f = START_FRAME; f <= frames; f++) {
	Stack.setSlice(f);
	intensities = getProfile();
	x_values = Array.getSequence(intensities.length);
	maxima = Array.findMaxima(intensities, 1);
	maxima_list[f-1] = maxima[0];		
}

// Generate the frame sequence, calibrate the values with frame interval and pixel size
// Plot it!
x_values = Array.getSequence(frames);
for (i = 0; i < x_values.length; i++) {
	x_values[i] *= time_interval;
	maxima_list[i] *= pixelWidth;
}
Plot.create("Meniscus over time", "time / " + Time , "meniscus position / " + X, x_values, maxima_list);

