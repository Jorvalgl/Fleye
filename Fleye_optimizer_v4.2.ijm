/* 
    This file is part of FLEYE an ImageJ macro developed to classify fly eyes attending to their degeneration level
    Copyright (C) 2014  Cristina Rueda Sabater, Sergio Díez Hermano, Diego Sánchez Romero,  María Dolores Ganfornina Álvarez and Jorge Valero Gómez-Lobo.

    FLEYE is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    FLEYE is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

//This macro has been developed by Dr Jorge Valero (jorge.valero@cnc.uc.pt). 
//If you have any doubt about how to use it, please contact me.

//License
Dialog.create("GNU GPL License");
Dialog.addMessage("FLEYE Copyright (C) 2014  Cristina Rueda Sabater, Sergio Diez Hermano, Diego Sanchez Romero,  Maria Dolores Ganfornina Alvarez and Jorge Valero Gomez-Lobo.");
Dialog.setInsets(10, 20, 0);
Dialog.addMessage("FLEYE  comes with ABSOLUTELY NO WARRANTY; click on help button for details.");
Dialog.setInsets(0, 20, 0);
Dialog.addMessage("This is free software, and you are welcome to redistribute it under certain conditions; click on help button for details.");
Dialog.addHelp("http://www.gnu.org/licenses/gpl.html");
Dialog.show();



scalecorr=scalecorr+0;
if (scalecorr==0){
	scaleUser=getNumber("What's the size (in microns) of a pixel in your images?", 1.85);
	scalecorr=1.85/scaleUser;
	//run("Set Scale...", "distance=1 known="+scaleUser+" pixel=1 unit=px global");
}

path = File.openDialog("Please, select a REPRESENTATIVE IMAGE to optimize parameters");
run("Bio-Formats Importer", "open=["+path+"] color_mode=Default open_files view=Hyperstack stack_order=XYCZT");
name=getTitle();
run("Stack to RGB");
selectWindow(name);
close();
selectWindow(name+" (RGB)");
rename(name);
//run("Open [Image IO]", "image=["+path+"]");
run("8-bit");
run("Set Scale...", "distance="+scalecorr+" known=1 pixel=1 unit=px global");
run("Colors...", "foreground=white background=white selection=yellow");

count=roiManager("count");
if (count>0){
	roiManager("Deselect");
	roiManager("Delete");
}

dir=getDirectory("Please, select a folder to save Optimal Parameters");
//Initial dialog
Dialog.create("Initial Parameters");
Dialog.addNumber("X displacement for the filter (pixel units): ", 5*scalecorr);
Dialog.addNumber("Y displacement for the filter (pixel units): ", 0);
//Dialog.addNumber("Contrast saturation: ", 1.5);
Dialog.addNumber("Rolling ball raidus for background subtraction: ", 50*scalecorr);
Dialog.addNumber("Find maxima noise tolerance: ", 20);
Dialog.addNumber("Grid cell Width: ", 20*scalecorr);
//Dialog.addNumber("Desired mean number of maxima per grid cell: ", 3.5);
Dialog.show();

Xdispl=Dialog.getNumber;
Ydispl=Dialog.getNumber;
//sat=Dialog.getNumber;
rolling=Dialog.getNumber;
tolerance=Dialog.getNumber;
GridWidth=Dialog.getNumber;
//pointscell=Dialog.getNumber;

roidef();
usercount=cellCounter();
roiManager("Deselect");
roiManager("Delete");
run("To ROI Manager");
setBatchMode(true);
target=0;
count2=-10;
count1=-20;
count=-30;
do{
	d=usercount-count;
	if (sqrt(pow(d, 2))!=target) {
		tolerance=tol(tolerance);
		selectWindow(name);
		run("Duplicate...", "title=Test");
		filter();
		count=NeNe();
		selectWindow("Test");
		run("Close");	
	}
	d=usercount-count;
	if (sqrt(pow(d, 2))!=target) {
		rolling=roll(rolling);
		selectWindow(name);
		run("Duplicate...", "title=Test");
		filter();
		count=NeNe();
		selectWindow("Test");
		run("Close");
		//if (count!=usercount) saturation(sat);
	}
	selectWindow(name);
	run("Duplicate...", "title=Test");
	filter();
	count2=count1;
	count1=count;
	count=NeNe();
	selectWindow("Test");
	run("Close");
	target++;
	d=usercount-count;
}while(count!=usercount && count!=count2 && sqrt(pow(d, 2))!=target-1);



sat=NaN;
print("\\Update:"+"User count: "+usercount+ " Automated count: "+count);
print("Tolerance: "+tolerance);
print("Rolling ball radius: "+rolling);
print("Saturation: "+sat);
selectWindow ("Counting tool");
run ("Close");
//gridoptimizer();
run ("Close All");
selectWindow("ROI Manager");
run ("Close");
//print("Grid width: "+GridWidth);


run("New... ", "name=[Parameters_"+name+"] type=Table");
print("[Parameters_"+name+"]", "\\Headings:Xdispl\tYdispl\tSaturation\tRolling\tTolerance\tGrid width");
print("[Parameters_"+name+"]", ""+Xdispl+"\t"+ Ydispl+"\t"+ sat+"\t"+ rolling+"\t"+ tolerance+"\t"+ GridWidth);
selectWindow("Parameters_"+name);
saveAs("Text", dir+"Parameters_"+name);

waitForUser("You can check the Parameters Table,\n then click OK to go back to the FLEYE menu");
selectWindow("Parameters_"+name);
run ("Close");
setBatchMode(false);

function roidef(){
	getDimensions(width, height,ch, sl,fr );
	makeRectangle((width/2)-25, (height/2)-25, 50*scalecorr, 50*scalecorr);
	//Xdispl=5;
	//Ydispl=0;
	do{
		waitForUser("Please, place the ROI in an adequate area for counting");
		//roiManager("Add");
		//roiManager("Show All without Labels");
		selec=selectionType();
		if (selec==-1) beep();
	}while(selec==-1);
	run("Add Selection...");
	run("Select None");
}

function cellCounter(){
	finish=false;
	x1=-1;
	y1=-1;
	flags1=-1;
	flags2=-1;
	run("New... ", "name=[Counting tool] type=Table");
	//print("[Counting tool]", "\\Clear");
	print("[Counting tool]","Left click to draw a point, Right click to finish. \n \npoints added to ROI Manager \n \n Counts \n" );
	setOption("DisablePopupMenu", true);
	count= roiManager("count");
	while (finish==false || count==1) {
	        getCursorLoc(x, y, z, flags);
	       // print (flags);
		 if ((x1!=x || y1!=y) && flags==16 && flags1!=flags && flags2!=flags){
			run("Line Width...", "line=20");
			makeOval(x-2, y-2, 4, 4);
			 x1=x;
			 y1=y;
			 roiManager("Add");
			 count= roiManager("count");
			  roiManager("Show All without labels");
			 print("[Counting tool]", "\\Update"+5+":"+count);
			 roiManager("Select", count-1);
			 roiManager("Rename", count);
			 run("Select None");
		 }
		if (flags==4 && flags1!=4) finish=getBoolean("Do you want to finish?");
		flags1=flags;
		flags2=flags1;
		
	}
	count= roiManager("count");
	 roiManager("Show All without labels");
	 print("[Counting tool]", "\\Update"+5+":"+count);
	 roiManager("Select", count-1);
	 roiManager("Rename", count);
	return(count);
}


//Surface filter;
function filter(){
	selectWindow("Test");
	roiManager("Select", 0);
	getSelectionBounds(x, y, width, height);
	makeRectangle(x-Xdispl, y-Ydispl, width+Xdispl, height+Ydispl);
	//waitForUser("");
	//makeRectangle(492/2-25-5, 394/2-25-0,  50+5, 50+0);
	run("8-bit");
	run("Subtract Background...", "rolling="+rolling+"");
	//roiManager("Select", 0);
	//waitForUser("This is what happens after subtract background, please click OK to continue");	
	setBackgroundColor(255, 255, 255);
	run("Clear Outside");
	selectWindow("Test");
	run("Select None");
	run("Duplicate...", "title=[Inverted]");
	run("Invert");
	
	run("Translate...", "x="+Xdispl+" y="+Ydispl+" interpolation=None");
	imageCalculator("Average", "Test", "Inverted");
	selectWindow("Inverted");
	close();
	selectWindow("Test");
	roiManager("Select", 0);
	getSelectionBounds(x, y, width, height);
	makeRectangle(x-Xdispl, y-Ydispl, width+Xdispl, height+Ydispl);
	//run("Enhance Contrast...", "saturated="+sat+"");
	//waitForUser("");
	roiManager("Select", 0);
}
//Find nearest neighbor;
function NeNe(){
	//run("8-bit");
	run("Find Maxima...", "noise="+tolerance+" output=Count");
	count=getResult("Count", 0);
	selectWindow("Results");
	run("Close");
	return(count);
	
}
function tol(tolerance){
		d0=0;
		d1=10000000000;
		d2=20000000000;
		dmejor=10000000000000000000000000000000000000;
		i=0;
		m=1;
		sub=2;
		do{
			i++;
			selectWindow(name);
			run("Duplicate...", "title=Test");
			filter();
			count=NeNe();
			selectWindow("Test");
			run("Close");
			d=usercount-count;
			toleranceprint=tolerance;
			if (d<0 && sub!=2){
				if (sub==1) tolerance=tolerance+10/m;
				if (sub==0) {
					m++;
					tolerance=tolerance+10/m;
					i=0;
					sub=2;
				}
			}
			if (d>0 && sub!=2){
				if (sub==0) tolerance=tolerance-10/m;
				if (sub==1) {
					m++;
					tolerance=tolerance-10/m;
					i=0;
					sub=2;
				}	
			}
			
			if (d<0 && i==1){
				tolerance=tolerance+10/m;
				sub=1;
			}
			if (d>0 && i==1){
				tolerance=tolerance-10/m;
				sub=0;
			}
			
			
			d2=d1;
			d1=d0;
			d0=d;
			if (d2==d1 && d1==d0) m=11;
			if (sqrt(pow(dmejor, 2))>sqrt(pow(d0, 2))){
				dmejor=d0;
				tolerancemejor=toleranceprint;
				countmejor=count;
			}
			print("\\Update:"+"Tolerance: "+toleranceprint+ " User count: "+usercount+ " Automated count: "+count);
		}while(sqrt(pow(d, 2))!=target && m<11);
		toleranceprint=tolerancemejor;
		count=countmejor;
		print("\\Update:"+"Tolerance: "+toleranceprint+ " User count: "+usercount+ " Automated count: "+count);
	return(toleranceprint);
}

function roll(rolling){
	
	d0=0;
		d1=10000000000;
		d2=20000000000;
		dmejor=10000000000000000000000000000000000000;
		i=0;
		m=1;
		sub=2;
		do{
			i++;
			selectWindow(name);
			run("Duplicate...", "title=Test");
			filter();
			count=NeNe();
			selectWindow("Test");
			run("Close");
			d=usercount-count;
			rollingprint=rolling;	
			if (d>0 && sub!=2){
				if (sub==1) rolling=rolling+10/m;
				if (sub==0) {
					m++;
					rolling=rolling+10/m;
					i=0;
					sub=2;
				}
			}
			if (d<0 && sub!=2){
				if (sub==0) rolling=rolling-10/m;
				if (sub==1) {
					m++;
					rolling=rolling-10/m;
					i=0;
					sub=2;
				}	
			}
			
			if (d>0 && i==1){
				rolling=rolling+10/m;
				sub=1;
			}
			if (d<0 && i==1){
				rolling=rolling-10/m;
				sub=0;
			}
			
			
			d2=d1;
			d1=d0;
			d0=d;
			if (d2==d1 && d1==d0) m=11;
			if (sqrt(pow(dmejor, 2))>sqrt(pow(d0, 2))){
				dmejor=d0;
				rollingmejor=rollingprint;
				countmejor=count;
			}
		print("\\Update:"+"Tolerance "+tolerance+" Rolling ball radius: "+rollingprint+ " User count: "+usercount+ " Automated count: "+count);
	//waitForUser("");
	}while(sqrt(pow(d, 2))!=target && m<11);
	rollingprint=rollingmejor;
	count=countmejor;
	print("\\Update:"+"Tolerance "+tolerance+" Rolling ball radius: "+rollingprint+ " User count: "+usercount+ " Automated count: "+count);
	return(rollingprint);
}

function saturation(sat){
	
		d0=0;
		d1=10000000000;
		d2=20000000000;
		i=0;
		m=1;
		sub=2;
		do{
			i++;
			selectWindow(name);
			run("Duplicate...", "title=Test");
			filter();
			count=NeNe();
			selectWindow("Test");
			run("Close");
			d=usercount-count;
			satprint=sat;	
			if (d>0 && sub!=2){
				if (sub==1) sat=sat-2/m;
				if (sub==0) {
					m++;
					sat=sat-1/m;
					i=0;
					sub=2;
				}
			}
			if (d<0 && sub!=2){
				if (sub==0) sat=sat+2/m;
				if (sub==1) {
					m++;
					sat=sat+1/m;
					i=0;
					sub=2;
				}	
			}
			
			if (d>0 && i==1){
				sat=sat-2/m;
				sub=1;
			}
			if (d<0 && i==1){
				sat=sat+2/m;
				sub=0;
			}
			
			
			d2=d1;
			d1=d0;
			d0=d;
		print("\\Update:"+"Saturation: "+satprint+" Tolerance "+tolerance+" Rolling ball radius: "+rolling+ " User count: "+usercount+ " Automated count: "+count);
	//waitForUser("");
	}while(d!=0 && m<11 && sat!=0);
	return(satprint);
}

function gridoptimizer(){
	
	run("Colors...", "foreground=white background=white selection=yellow");
	if (isOpen("ROI Manager")) {
		selectWindow ("ROI Manager");
		run("Close");
	}
	do {
		waitForUser("Please, draw ONE ROI for grid optimization and click OK when finish ");
		if (selectionType()!=-1) roiManager("Add");
		rois=roiManager("count");
		if (rois!=1) beep();	
		} while (rois!=1);
	cropping();
	filtergrid();	
	run("Find Maxima...", "noise="+tolerance+" output=[Single Points]");
	
	meanpoints=pointspercell();
	dist=sqrt(pow(meanpoints-pointscell, 2));
	//print("Mean max per cell: "+meanpoints);
	cleangrid();
	GW1=GridWidth;
	dist1=dist;
	if (meanpoints<pointscell) GridWidth=GridWidth*2;
	if (meanpoints>pointscell) GridWidth=GridWidth/2;
	meanpoints=pointspercell();
	//waitForUser("");
	cleangrid();
	
	while (meanpoints!=pointscell){
		GW2=GW1;
		GW1=GridWidth;
		if (meanpoints<pointscell) GridWidth=GW1+sqrt(pow((GW1-GW2)/2, 2));
		if (meanpoints>pointscell) GridWidth=GW1-sqrt(pow((GW1-GW2)/2, 2));
		meanpoints=pointspercell();
		//waitForUser("");
		cleangrid();
		dist2=dist1;
		dist1=dist;
		dist=sqrt(pow(meanpoints-pointscell, 2));
		//print(GridWidth+" "+meanpoints+" "+ dist);
		if (dist2<=dist1 && dist1<dist){
			
			pointscell=meanpoints;
			GridWidth=GW2;
		}
	}
	print("Mean elements per cell: "+meanpoints);
}



//Region cropping;
function cropping(){
	
	run("8-bit");
	run("Subtract Background...", "rolling="+rolling+"");
	//waitForUser("This is what happens after subtract background, please click OK to continue");	
	setBackgroundColor(255, 255, 255);
	roiManager("Select", 0);
	//waitForUser("");
	run("Clear Outside");
}

//Surface filter;
function filtergrid(){
	selectWindow(name);
	run("Select None");
	run("Duplicate...", "title=[Inverted]");
	run("Invert");
	
	run("Translate...", "x="+Xdispl+" y="+Ydispl+" interpolation=None");
	imageCalculator("Average", name,"Inverted");
	selectWindow("Inverted");
	close();
	selectWindow(name);
	roiManager("Select", 0);
	//run("Enhance Contrast...", "saturated="+sat+"");
}

//this function returns the mean number of maxima per grid cell
function pointspercell(){ 
	grid();
	GridResults();
	meanp=cellpoints();
	return(meanp);
}

function grid(){
	selectWindow(name+" Maxima");
	color=getValue("color.foreground");
	//print(color);
	if (color==0) run("Invert LUT");
	TestGrids();
	roiManager("Select",0);
	getSelectionBounds(x, y, width, height);
	run("Select None");
	//run("Duplicate...", "title=[TestGrid] duplicate channels=1-3 slices=1-2");
	cf=0;
	xf = x+width;
	yn = y;
	yf = y+height;
	//GridWidth = 20;
	for (yn=y; yn<=yf; yn=yn+GridWidth){
		for (xn=x; xn<=xf; xn=xn+GridWidth){
			cf=++cf;
			roisquare();
		}
	}
	selectWindow("TestGrid Filled");
	close();
	selectWindow("TestGrid Line");
	close();
	selectWindow(name+" Maxima");
	roiManager("Show All with labels");
	roiManager("Show All");
	
}



function roisquare(){
	//run("Overlay Options...", "stroke=blue width=1");
	selectWindow("TestGrid Line");
	run("Specify...", "width="+GridWidth+" height="+GridWidth+" x="+xn+" y="+yn+" slice=1");
	getStatistics(area, mean);
	if (mean==0){
		selectWindow("TestGrid Filled");
		run("Specify...", "width="+GridWidth+" height="+GridWidth+" x="+xn+" y="+yn+" slice=1");
		getStatistics(area, mean);
		if (mean>0){
			selectWindow(name+" Maxima");
			run("Specify...", "width="+GridWidth+" height="+GridWidth+" x="+xn+" y="+yn+" slice=1");
			roiManager("Add");
			roiManager("Show All without labels");
			roiManager("Show None");
			
		}
		run("Select None");
	}
}

function TestGrids(){
	run("Select None");
	run("Duplicate...", "title=[TestGrid Line]");
	run("Duplicate...", "title=[TestGrid Filled]");
	selectWindow("TestGrid Line");
	roiManager("Select",0);
	setBackgroundColor(0, 0, 0);
	run("Clear");
	setForegroundColor(255, 255, 255);
	run("Line Width...", "line=1");
	run("Draw");
	run("Select None");
	selectWindow("TestGrid Filled");
	roiManager("Select",0);
	run("Enlarge...", "enlarge=-1");
	setBackgroundColor(255, 255, 255);
	run("Clear");
	run("Select None");
}

function GridResults(){
	run("Set Measurements...", "area centroid center skewness kurtosis area_fraction redirect=None decimal=4");
	setThreshold(1,255);
	roiselect();
	roiManager("Measure");
}

function roiselect(){
	roiManager("Deselect");
	rois=roiManager("count");
	rois=rois-1;
	roiselection=newArray(rois);
	for (i=0; i<rois; i++) roiselection[i]=i+1;
	roiManager("Select", roiselection);
}

function cellpoints(){
	sumPoints=0;
	for (i=0; i<nResults; i++){
		points=getResult("%Area", i)*getResult("Area", i)/100;
		sumPoints=sumPoints+points;
		}	
	meanPoints=sumPoints/nResults;
	return(meanPoints);
}

//eliminate rois and results
function cleangrid(){
	roiManager("Deselect");
	roisnum=roiManager("count");
	for (roi=1; roi<roisnum; roi++) {
		roiManager("Select", 1);
		roiManager("Delete");
	}
	selectWindow("Results");
	run("Close");	
}
