/* 
    This file is part of FLEYE a package of ImageJ macros developed to classify fly eyes attending to their degeneration level
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

//scale normalization
scaleUser=getNumber("What's the size (in microns) of a pixel in your images?", 1.85);
scalecorr=1.85/scaleUser;

// parameters of the model
var indep=newArray(84.3666, 60.0043, 29.0704, 1.2994);
var DISTMED=newArray(-13.6811, -11.0979, -4.4487, 0.2421);
var DISTSKEW=newArray(20.3917, 15.0051, 7.6631, -17.7463);
var LOGNNVAR=newArray(-17.3201, -6.9768, -3.3085, -0.1040);
var NOPOINTS=0;

//table handling variable
var infovar=0;


//Initial dialog
Dialog.create("OPTIONS");
Dialog.addCheckbox("\tPRE-OPTIMIZED PARAMETERS", true);
Dialog.setInsets(-6, 40, 0);
Dialog.addMessage("(Remember!!! Predefined parameters are assumed to be CALIBRATED)");
Dialog.setInsets(0, 50, 0);
Dialog.addCheckbox("All parameter files", true);
Dialog.setInsets(5, 120, 0);
Dialog.addMessage("NUMBER OF GROUPS TO ANALYSE");
Dialog.setInsets(0, -100, 0);
Dialog.addNumber("", 1);
Dialog.setInsets(-6, 100, 0);
Dialog.addMessage("(Images from groups should be separated in different folders)");
Dialog.setInsets(20, 0, 0);
Dialog.addNumber ("Define number of intervals for Frequency histograms", 200);
Dialog.show();

prepar=Dialog.getCheckbox;
optionprepar=Dialog.getCheckbox;
groups=Dialog.getNumber();
intervals=Dialog.getNumber();

//Groups definition dialog
Dialog.create("Groups definition");
for (i=1; i<=groups; i++) Dialog.addString("Group "+i+":", "group"+i, 25);
Dialog.show();

groupname=newArray(groups);
dirgroup=newArray(groups);
dirRoi=newArray(groups);
for (i=0; i<groups; i++) groupname[i]=Dialog.getString();

//fore/background colors
run("Colors...", "foreground=white background=white selection=yellow");

//folders selection
for (i=0; i<groups; i++) {
	dirgroup[i]=getDirectory ("Please, select the folder containing the IMAGES of group "+ groupname[i]);
	dirRoi[i]=getDirectory("Please, select the folder containing the ROIs of group "+ groupname[i]);
}
	dirRes=getDirectory ("Please, select a folder for RESULTS (common for all groups)");

//selection and loading of parameter files
parname=" ";
if (prepar==true){
		param=getDirectory("Please, select the folder containig the Parameters file");
		files=getFileList(param);
		Dialog.create("PARAMETER FILES");
		Dialog.addMessage("Please, select the files that you want to use");
		for(i=0; i<files.length; i++){
			if (startsWith(files[i], "Parameters_")){
				if (optionprepar==true) Dialog.addCheckbox(files[i], true);
				else Dialog.addCheckbox(files[i], false); 
			}
		}
		Dialog.show();
		sumXdispl=0;
		sumYdispl=0;
		sumsat=0;
		sumroll=0;
		sumtol=0;
		sumgridsize=0;
		n=0;
		for(i=0; i<files.length; i++){
			if (startsWith(files[i], "Parameters_")){
				if(Dialog.getCheckbox==true){
					parameters=File.openAsString(param+files[i]);
					linepar=split(parameters, "\n");
					col=split(linepar[1], "\t");
					sumXdispl=sumXdispl+parseFloat(col[0]);
					sumYdispl=sumYdispl+parseFloat(col[1]);
					sumsat=sumsat+parseFloat(col[2]);
					sumroll=sumroll+parseFloat(col[3]);
					sumtol=sumtol+parseFloat(col[4]);
					sumgridsize=sumgridsize+parseFloat(col[5]);
					n++;
					}
				}
			}
			Xdispl=sumXdispl/n;
			Ydispl=sumYdispl/n;
			sat=sumsat/n;
			roll=sumroll/n;
			tol=sumtol/n;
			gridsize=sumgridsize/n;	
			Dialog.create("PARAMETERS");
			Dialog.addNumber("X displacement for the filter (pixel units): ", Xdispl);
			Dialog.addNumber("Y displacement for the filter (pixel units): ", Ydispl);
			Dialog.addNumber("Contrast saturation: ", sat);
			Dialog.addNumber("Rolling ball raidus for background subtraction: ", roll);
			Dialog.addNumber("Find maxima noise tolerance: ", tol);
			Dialog.addNumber("Grid cell size:", gridsize);
			Dialog.show();
		}
		
//Parameters dialog
else {
	Dialog.create("PARAMETERS");
	Dialog.addNumber("X displacement for the filter (pixel units): ", 5*scalecorr);
	Dialog.addNumber("Y displacement for the filter (pixel units): ", 0);
	Dialog.addNumber("Contrast saturation: ", NaN);
	Dialog.addNumber("Rolling ball raidus for background subtraction: ", 50*scalecorr);
	Dialog.addNumber("Find maxima noise tolerance: ", 20);
	Dialog.addNumber("Grid cell size:", 20*scalecorr);
	Dialog.show();
}

Xdispl=Dialog.getNumber;
Ydispl=Dialog.getNumber;
sat=Dialog.getNumber;
rolling=Dialog.getNumber;
tolerance=Dialog.getNumber;
GridWith=Dialog.getNumber;

//table preparation
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

tablearray=newArray("Date", "time","Xdisp","Ydisp", "Contrast Sat", "Roll rad", "Tolerance", "Cell size");
tablecreator("Parameters", tablearray);
date=""+month+"/"+dayOfMonth+"/"+year;
time=""+hour+":"+minute+":"+second;
tablearray=newArray(date, time, Xdispl, Ydispl, sat, rolling, tolerance, GridWith);
tableprinter("Parameters", tablearray);

//generation of results folders
folders();

// groups analysis
for (arr=0; arr<groups; arr++) analizar();
savetab("Parameters", "Means");
selectWindow("Parameters");
run("Close");
meantables();


//FUNCTIONS


//Open, process and analyse images
function analizar(){
	tables(groupname[arr]);
	files=getFileList(dirgroup[arr]);
	for (i=0; i<files.length; i++) openfile();
	savetab(""+groupname[arr]+"_Nearest Neighbor",groupname[arr] );
	//selectWindow(""+groupname[arr]+"_Nearest Neighbor");
	//run("Close");
	//savetab("Points per Cell");
	//savetab("Skewness");
	//savetab("Kurtosis");
	savetab(""+groupname[arr]+"_Distance to the center of mass", groupname[arr]);
	//selectWindow (""+groupname[arr]+"_Distance to the center of mass");
	//run("Close");
	//savetab("Cells percentages");
	savetab(""+groupname[arr]+"_Classification", groupname[arr]);
	graphics(groupname[arr]);
	//print("I HAVE FINISHED MY WORK");
	selectWindow(""+groupname[arr]+"_Accumulated probability");
	saveAs("Tiff", dirRes+groupname[arr]+"/"+groupname[arr]+"_Accumulated probability");
	selectWindow(""+groupname[arr]+"_Frequency_histogram");
	saveAs("Tiff", dirRes+groupname[arr]+"/"+groupname[arr]+"_Frequency_histogram");
}


//function to open the images
function openfile(){
	if (isOpen("ROI Manager")) {
		selectWindow("ROI Manager");
		run("Close"); 
	}
	if (File.exists(dirRoi[arr]+files[i]+".zip")){
		name=files[i];
		//run("Open [Image IO]", "image=["+dir+files[i]+"]");
		run("Bio-Formats Importer", "open=["+dirgroup[arr]+files[i]+"] color_mode=Default open_files view=Hyperstack stack_order=XYCZT");
		name=getTitle();
		run("Stack to RGB");
		selectWindow(name);
		close();
		selectWindow(name+" (RGB)");
		rename(name);
		run("Set Scale...", "distance="+scalecorr+" known=1 pixel=1 unit=px global");
		roiManager("Open", dirRoi[arr]+files[i]+".zip");
		cropping();
		filter();
		//run("8-bit");
		//roiManager("Select", 0);
		NeNe();
		grid();
		GridResults();
		//exit();
		datagrid();
		resetall();
	}
	else print("NO ROI found: "+ dirRoi[arr]+files[i]+".zip");
}

//tables generator
function tables (prefijo){
	tablearray=newArray("Date", "time", "Image", "Points", "Nearest Neighbor", "StdDv", "Var");
	tablecreator (prefijo+"_Nearest Neighbor", tablearray);
	tablearray=newArray("Date", "time", "Image", "DEGCALL", "IREG", "PP0","PP1","PP2","PP3","PP4");
	tablecreator (prefijo+"_Classification", tablearray);
	

    tablearray=newArray("Date", "time", "Image", "Cells", "Mean", "StdDv", "Var", "Skew");
	//tablecreator("Points per Cell", tablearray);
	//tablecreator("Skewness", tablearray);
	//tablecreator("Kurtosis", tablearray);
	tablecreator(prefijo+"_Distance to the center of mass", tablearray);
	//tablearray=newArray("Date", "time", "Image", "Cells", "%<2", "%<4", "%<6", "%<8");
	//tablecreator("Cells percentages", tablearray);
}

//Function to create tables
function tablecreator(tabname, tablearray){
	run("New... ", "name=["+tabname+"] type=Table");
	headings=tablearray[0];
	for (i=1; i<tablearray.length; i++)headings=headings+"\t"+tablearray[i];
	print ("["+tabname+"]", "\\Headings:"+ headings);
}

//Function to populate tables
function tableprinter(tabname, tablearray){
	line=tablearray[0];
	for (i=1; i<tablearray.length; i++) line=line+"\t"+tablearray[i];
	print ("["+tabname+"]", line);
}

//Region cropping and subtract backround
function cropping(){
	run("8-bit");
	run("Subtract Background...", "rolling="+rolling+"");
	//waitForUser("This is what happens after subtract background, please click OK to continue");	
	setBackgroundColor(255, 255, 255);
	roiManager("Select", 0);
	run("Clear Outside");
}

//Surface filter;
function filter(){
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

//Find nearest neighbour and create maxima image;
function NeNe(){
	//run("8-bit");
	run("Find Maxima...", "noise="+tolerance+" output=List");
	run("Find Maxima...", "noise="+tolerance+" output=[Single Points]");
	selectWindow("Results");
	point=getInfo();
	pointline=split(point, "\n");
	NN=newArray(pointline.length-1);
	Array.fill(NN, 0);
	for (p=1; p<pointline.length; p++){
		pointcolumn=split(pointline[p], "\t");
		Xp=pointcolumn[1];
		Yp=pointcolumn[2];
		d=0;
		for (n=1; n<pointline.length; n++){
			
			pointc=split(pointline[n], "\t");
			Xc=pointc[1];
			Yc=pointc[2];
			X=parseFloat(Xc)-parseFloat(Xp);
			Y=parseFloat(Yc)-parseFloat(Yp);
			X2=pow(X,2);
			Y2=pow(Y,2);
			sum=X2+Y2;
			dtemp=pow(sum,1/2);
			//print(n, p);
			if (d!=0 && dtemp!=0) {
				//if (n=1) d=dtemp;
				if (dtemp<d) d=dtemp;	
			}
			if (d==0 && n!=p) d=dtemp;
			
			//print(d, dtemp);
		}
		//print (d);
		NN[p-1]=d/scalecorr;
	}
	Array.getStatistics(NN, min, max, mean, stdDev);
	squsum=0;
	for (i=0; i<NN.length; i++){
		squsum=pow((NN[i]-mean),2)+squsum;	
	}
	variance=squsum/NN.length;
	
	if (NN.length==0) NOPOINTS=1;
	tablearray=newArray(date, time, name, NN.length, mean, stdDev, variance);
	tableprinter(""+groupname[arr]+"_Nearest Neighbor", tablearray);
	
	selectWindow("Results");
	IJ.renameResults("Point coordenates");
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
	//GridWith = 20;
	for (yn=y; yn<=yf; yn=yn+GridWith){
		for (xn=x; xn<=xf; xn=xn+GridWith){
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


//this function generates the grid
function roisquare(){
	//run("Overlay Options...", "stroke=blue width=1");
	selectWindow("TestGrid Line");
	run("Specify...", "width="+GridWith+" height="+GridWith+" x="+xn+" y="+yn+" slice=1");
	getStatistics(area, mean);
	if (mean==0){
		selectWindow("TestGrid Filled");
		run("Specify...", "width="+GridWith+" height="+GridWith+" x="+xn+" y="+yn+" slice=1");
		getStatistics(area, mean);
		if (mean>0){
			selectWindow(name+" Maxima");
			run("Specify...", "width="+GridWith+" height="+GridWith+" x="+xn+" y="+yn+" slice=1");
			roiManager("Add");
			roiManager("Show All without labels");
			roiManager("Show None");
			
		}
		run("Select None");
	}
}

//This function creates images for grid generation
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

//This function obtains data from the grid
function GridResults(){
	run("Set Measurements...", "area centroid center skewness kurtosis area_fraction redirect=None decimal=4");
	setThreshold(1,255);
	roiselect();
	roiManager("Measure");
}

//function to select single grid cells
function roiselect(){
	roiManager("Deselect");
	rois=roiManager("count");
	rois=rois-1;
	roiselection=newArray(rois);
	for (i=0; i<rois; i++) roiselection[i]=i+1;
	roiManager("Select", roiselection);
}


//This function obtains several data from the grid analysis
function datagrid(){
	sumPoints=0;
	sumDist=0;
	//PorCelMinor2=0;
	//PorCelMinor4=0;
	//PorCelMinor6=0;
	//PorCelMinor8=0;
	//nSkew=0;
	//nKurt=0;
	ndist=0;
	for (i=0; i<nResults; i++){
		points=getResult("%Area", i)*getResult("Area", i)/100;
		//if (points<2) PorCelMinor2++;
		//if (points<4) PorCelMinor4++;
		//if (points<6) PorCelMinor6++;
		//if (points<8) PorCelMinor8++;
		sumPoints=sumPoints+points;
		if (points>0) {
			dist=sqrt((pow(getResult("X", i)-getResult("XM", i), 2))+((pow(getResult("Y", i)-getResult("YM", i), 2))));
			sumDist=sumDist+dist;
			ndist++;
		}
		//skew=getResult("Skew", i);
		//if (isNaN(skew)==false){
			//sumSkew=sumSkew+skew;
			//nSkew++;
		//}
		//kurt=getResult("Kurt", i);
		//if (isNaN(kurt)==false){
			//sumKurt=sumKurt+kurt;
			//nKurt++;
		//}
		
	}	
	//PorCelMinor2=(PorCelMinor2/nResults)*100;
	//PorCelMinor4=(PorCelMinor4/nResults)*100;
	//PorCelMinor6=(PorCelMinor6/nResults)*100;
	//PorCelMinor8=(PorCelMinor8/nResults)*100;
	meanPoints=sumPoints/nResults;
	meanDist=sumDist/ndist;
	//meanSkew=sumSkew/nSkew;
	//meanKurt=sumKurt/nKurt;
	squsumDist=0;
	cubsumDist=0;
	for (i=0; i<nResults; i++){
		points=getResult("%Area", i)*getResult("Area", i)/100;
		squsumPoints=pow((points-meanPoints),2)+squsumPoints;
		cubsumPoints=pow((points-meanPoints),3)+cubsumPoints;
		if (points>0) {
			dist=sqrt((pow(getResult("X", i)-getResult("XM", i), 2))+((pow(getResult("Y", i)-getResult("YM", i), 2))));
			squsumDist=pow((dist-meanDist),2)+squsumDist;
			cubsumDist=pow((dist-meanDist),3)+cubsumDist;
		}
		//skew=getResult("Skew", i);
		//if (isNaN(skew)==false){
			//squsumSkew=pow((skew-meanSkew),2)+squsumSkew;
			//cubsumSkew=pow((skew-meanSkew),3)+cubsumSkew;
		//}		
		//kurt=getResult("Kurt", i);
		//if (isNaN(kurt)==false){
			//squsumKurt=pow((kurt-meanKurt),2)+squsumKurt;
			//cubsumKurt=pow((kurt-meanKurt),3)+cubsumKurt;
		//}
	}
	
	//variancePoints=squsumPoints/nResults;
	//StdDvPoints=sqrt(variancePoints);
	//SkewPoints=(cubsumPoints/nResults)/pow(StdDvPoints,3);
	
	varianceDist=squsumDist/ndist;
	StdDvDist=sqrt(varianceDist);
	SkewDist=(cubsumDist/ndist)/pow(StdDvDist,3);
	
	//varianceSkew=squsumSkew/nSkew;
	//StdDvSkew=sqrt(varianceSkew);
	//SkewSkew=(cubsumSkew/nSkew)/pow(StdDvSkew,3);
	
	//varianceKurt=squsumKurt/nKurt;
	//StdDvKurt=sqrt(varianceKurt);
	//SkewKurt=(cubsumKurt/nKurt)/pow(StdDvKurt,3);

	//tablearray=newArray(date, time, name, nResults, meanPoints, StdDvPoints, variancePoints, SkewPoints); 
	//tableprinter("Points per Cell", tablearray);
	tablearray=newArray(date, time, name, ndist, meanDist, StdDvDist, varianceDist, SkewDist); 
	tableprinter(""+groupname[arr]+"_Distance to the center of mass", tablearray);
	//tablearray=newArray(date, time, name, nSkew, meanSkew, StdDvSkew, varianceSkew, SkewSkew); 
	//tableprinter("Skewness", tablearray);
	//tablearray=newArray(date, time, name, nKurt, meanKurt, StdDvKurt, varianceKurt, SkewKurt); 
	//tableprinter("Kurtosis", tablearray);
	//tablearray=newArray(date, time, name, nResults, PorCelMinor2, PorCelMinor4, PorCelMinor6, PorCelMinor8); 
	//tableprinter("Cells percentages", tablearray);
	model();
}

//this function all close windows, except table ones
function resetall(){
	selectWindow(name);
	close();
	selectWindow(name+" Maxima");
	close();
	list = getList("window.titles");
     for (i=0; i<list.length; i++){
	     winame = list[i];
	     //print(winame);
	     noclose=false;
	     for (ii=0; ii<groups; ii++) if (startsWith(winame, groupname[ii])) noclose=true; 
		 if (noclose==false && winame!="Parameters"){
		     selectWindow(winame);
		     run("Close");
	     }
     }
}

//This function allows saving table (tablename)
function  savetab(tablename, folder){
	//tablename=getList("window.titles");
		selectWindow(tablename);
		 saveAs("Text", dirRes+folder+"/"+tablename+".xls");
	}

//classification algorithm
function model(){
	selectWindow(""+groupname[arr]+"_Distance to the center of mass");
	tableinfo=getInfo();
	Ltab=split(tableinfo, "\n");
	i=Ltab.length-1;
	infoTab(""+groupname[arr]+"_Distance to the center of mass", i, 2);
	imagename=infovar;
	PPi=newArray(5);
	if (NOPOINTS==1){
		DEGCALL=1; 
		IREG=1;
		PPi[4]=1;
		NOPOINTS=0;
	}
	else{
			infoTab(""+groupname[arr]+"_Distance to the center of mass", i, 4);
			distmed=parseFloat(infovar);
			infoTab(""+groupname[arr]+"_Distance to the center of mass", i, 7);
			distskew=parseFloat(infovar);
			infoTab(""+groupname[arr]+"_Nearest Neighbor", i, 6);
			nnvar=parseFloat(infovar);
			lognnvar=log(nnvar);
			ai=newArray(4);
			F=1;
			for (m=0; m<4; m++){
				ai[m]=indep[m]+distmed*DISTMED[m]+distskew*DISTSKEW[m]+lognnvar*LOGNNVAR[m];
				F=F+exp(ai[m]);
			}
			for (m=0; m<4; m++){
				PPi[m]=exp(ai[m])/F;
			}
			PPi[4]=1/F;
			B=(PPi[4]+PPi[3])/(PPi[0]+PPi[1]);
			DEGCALL=B/(1+B);
			IREG=((5*PPi[0]+4*PPi[1]+3*PPi[2]+2*PPi[3]+PPi[4])-1)/4;
	}
		tablearray=newArray(date, time, imagename, DEGCALL, IREG, PPi[0], PPi[1], PPi[2], PPi[3], PPi[4]); 
		tableprinter(""+groupname[arr]+"_Classification", tablearray);
			
}

//This function obtains info from tables, line and column values should be numeric
function infoTab(tablename, line, column){
	selectWindow(tablename);
	tableinfo=getInfo();
	Ltab=split(tableinfo, "\n");
	Ctab=split(Ltab[line], "\t");
	infovar=Ctab[column];
}

//graphics generation 
function graphics(prefijo){
		selectWindow(prefijo+"_Classification");
		tableinfo=getInfo();
		Ltab=split(tableinfo, "\n");
		limit=Ltab.length;
		limit=limit+limit/10;
		histograma(prefijo);
		//bargraph(prefijo+"_Degeneration probability", 3, "green", "blue", "yellow", "red");
		bargraph2(prefijo, "EYE");
}

//histogram generation
function histograma(prefijo){
	intervals2=intervals-1;
	selectWindow(prefijo+"_Classification");
		tableinfo=getInfo();
		Ltab=split(tableinfo, "\n");
		//limit=Ltab.length;
		//limit=limit+limit/10;
	nn=0;
	histodata=newArray(intervals);
	for (n=1; n<Ltab.length; n++){
		infoTab(""+prefijo+"_Classification", n, 4);
		value=parseFloat(infovar);
		//print("val: "+value);
		for (iii=0; iii<intervals; iii++) {
			minI=(iii)/intervals2-(1/(2*intervals2));
			maxI=(iii)/intervals2+(1/(2*intervals2));
			if (value>=minI && value<maxI) {
				histodata[iii]++;
			}
		}
		
	}
	for (iii=0; iii<intervals; iii++) histodata[iii]=histodata[iii]/(Ltab.length-1);
	
	Plot.create(prefijo+"_Frequency_histogram", "Regularity index", "Frequency");
	Plot.setFrameSize(504.4, 300);
	Plot.setLimits(-0.1, 1.14, -0.1, 1.1);
	for (iii=0; iii<intervals; iii++){
		xmin=(iii/intervals2)-(1/(2*intervals2));
		xmax=(iii/intervals2)+(1/(2*intervals2));
		index=histodata[iii];
		//if (index==0) index=0.1;
		//print(index);
		if (xmax>0.9375) Plot.setColor("#00FF00");
		if (xmax<=0.9375 && xmax>0.7188) Plot.setColor("#008000");
		if (xmax<=0.7188 && xmax>0.5) Plot.setColor("#ADFF2F");
		if (xmax<=0.5 && xmax>0.2812) Plot.setColor("#FFFF00");  
		if (xmax<=0.2812 && xmax>0.0625) Plot.setColor("#FFA500"); 
		if (xmax<=0.0625) Plot.setColor("#FF0000"); 
		for (i=index; i>=0; i=i-0.001) Plot.add("line", newArray(xmin,xmax), newArray(i,i));
	}
	Plot.show;
}

//Old Graphs generation (for degeneration probability, not used)
function bargraph(indexname, col, mincol, minmed, maxmed, maxcol){	
	Plot.create(indexname, "EYE", indexname+" index");
		Plot.setFrameSize(500+limit, 300);
		Plot.setLimits(0, limit, -0.1, 1.1);
		//Plot.setLineWidth(2);
		for (n=1; n<Ltab.length; n++){
			infoTab(""+prefijo+"_Classification", n, col);
			index=parseFloat(infovar);
			if (index>0.75) Plot.setColor(maxcol);
			if (index<=0.75 && index>0.5) Plot.setColor(maxmed);
			if (index<=0.5 && index>0.25) Plot.setColor(minmed); 
			if (index<=0.25) Plot.setColor(mincol); 
			xmin=n-0.25;
			xmax=n+0.25;
			for (i=index; i>0; i=i-0.001) Plot.add("line", newArray(xmin,xmax), newArray(i,i));
			}	
		Plot.show;
}

//Accumulated probability graphs generation
function bargraph2(prefijo, group){	
	Plot.create(prefijo+"_Accumulated probability", group,  "PP index");
		Plot.setFrameSize(400+limit, 300);
		Plot.setLimits(0, limit+1, -0.1, 1.1 );
		
		for (n=1; n<Ltab.length; n++){
			xmin=n-0.25;
			xmax=n+0.25;
			infoTab(""+prefijo+"_Classification", n, 5);
			index=parseFloat(infovar);
			Plot.setColor("green");
			setJustification("left");
			Plot.addText("PPO",0.9, 0.30);
			for (i=index; i>0; i=i-0.001) Plot.add("line", newArray(xmin,xmax), newArray(i,i));
			infoTab(""+prefijo+"_Classification", n, 6);
			index1=index+parseFloat(infovar);
			Plot.setColor("blue");
			setJustification("left");
			Plot.addText("PP1",0.9, 0.40);
			for (i=index1; i>index; i=i-0.001) Plot.add("line", newArray(xmin,xmax), newArray(i,i));
			infoTab(""+prefijo+"_Classification", n, 7);
			index2=index1+parseFloat(infovar);
			Plot.setColor("yellow");
			setJustification("left");
			Plot.addText("PP2",0.9, 0.50);
			for (i=index2; i>index1; i=i-0.001) Plot.add("line", newArray(xmin,xmax), newArray(i,i));
			infoTab(""+prefijo+"_Classification", n, 8);
			index3=index2+parseFloat(infovar);
			Plot.setColor("orange");
			setJustification("left");
			Plot.addText("PP3",0.9, 0.60);
			for (i=index3; i>index2; i=i-0.001) Plot.add("line", newArray(xmin,xmax), newArray(i,i));
			infoTab(""+prefijo+"_Classification", n, 9);
			index4=index3+parseFloat(infovar);
			Plot.setColor("red");
			setJustification("left");
			Plot.addText("PP4",0.9, 0.70);
			for (i=index4; i>index3; i=i-0.001) Plot.add("line", newArray(xmin,xmax), newArray(i,i));
			}	
		Plot.show;
}

//create and save mean tables
function meantables(){
	tablesmean("Mean");
	for(i=0; i<groups; i++){
		meandata("_Classification");
		meandata("_Distance to the center of mass");
		meandata("_Nearest Neighbor");
	}
	savetab("Mean_Classification", "Means");
	savetab("Mean_Distance to the center of mass", "Means");
	savetab("Mean_Nearest Neighbor", "Means");
	selectWindow("Mean_Classification");
	tableinfo=getInfo();
	Ltab=split(tableinfo, "\n");
	limit=Ltab.length;
	limit=limit+limit/10;
	bargraph2("Mean", "Group");
	selectWindow("Mean_Accumulated probability");
	saveAs("Tiff", dirRes+"Means/"+"Mean_Accumulated probability");
	
}

//print mean tables
function meandata(tabname){
	selectWindow(groupname[i]+tabname);
	tableinfo=getInfo();
	linetable=split(tableinfo, "\n");
	if (linetable.length>1){
	coltable=split(linetable[1], "\t");
	means=newArray(coltable.length);
	infoTab(""+groupname[i]+""+tabname, 1, 0);
	means[0]=infovar;
	infoTab(""+groupname[i]+""+tabname, 1, 1);
	means[1]=infovar;
	means[2]=groupname[i];
	for(c=3; c<coltable.length; c++){
		n=0;
		for (t=1; t<linetable.length; t++){
			infoTab(""+groupname[i]+""+tabname, t, c);
			means[c]=means[c]+infovar;
			n++;
		}
		means[c]=means[c]/n;
	}
	tableprinter("Mean"+tabname, means);
	}
}

//generates mean tables
function tablesmean (prefijo){
	tablearray=newArray("Date", "time", "Group", "Points", "Nearest Neighbor", "StdDv", "Var");
	tablecreator (prefijo+"_Nearest Neighbor", tablearray);
	tablearray=newArray("Date", "time", "Group", "DEGCALL", "IREG", "PP0","PP1","PP2","PP3","PP4");
	tablecreator (prefijo+"_Classification", tablearray);
    tablearray=newArray("Date", "time", "Group", "Cells", "Mean", "StdDv", "Var", "Skew");
	tablecreator(prefijo+"_Distance to the center of mass", tablearray);
}

//this function creates result folders
function folders(){
	for (i=0; i<groups; i++) {
		File.makeDirectory(dirRes+groupname[i]);
	}
	File.makeDirectory(dirRes+"Means");
}
