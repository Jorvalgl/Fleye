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
Dialog.addMessage("FLEYE  Copyright (C) 2014  Cristina Rueda Sabater, Sergio Diez Hermano, Diego Sanchez Romero,  Maria Dolores Ganfornina Alvarez and Jorge Valero Gomez-Lobo.");
Dialog.setInsets(10, 20, 0);
Dialog.addMessage("FLEYE  comes with ABSOLUTELY NO WARRANTY; click on help button for details.");
Dialog.setInsets(0, 20, 0);
Dialog.addMessage("This is free software, and you are welcome to redistribute it under certain conditions; click on help button for details.");
Dialog.addHelp("http://www.gnu.org/licenses/gpl.html");
Dialog.show();


dir=getDirectory ("Please, select the folder containing the IMAGES");
dirP=getDirectory("Please, select the folder for PROCESSED IMAGES");
dirNP=getDirectory("Please, select the folder for NON-Processed IMAGES");
dirRoi=getDirectory("Please, select the folder for ROIs");

files=getFileList(dir);
i=0;

do{

	openfile();
	i++;
	cont= getBoolean("Do you want to CONTINUE?");
}
while	(i<files.length && cont==true);

function openfile(){

	//Opening and inital treatment of image (compilation of image parameters);
	//run("Open [Image IO]", "image=["+dir+files[i]+"]");
	run("Bio-Formats Importer", "open=["+dir+files[i]+"] color_mode=Default open_files view=Hyperstack stack_order=XYCZT");
	name=getTitle();
	run("Stack to RGB");
	selectWindow(name);
	close();
	selectWindow(name+" (RGB)");
	rename(name);
	//run("Bio-Formats", "open=["+dir+files[i]+"] color_mode=Default open_files view=Hyperstack stack_order=Default");
	//run("Set Scale...", "distance="+scale+" known=1 pixel=1 unit=micron");
	name=files[i];
	//Clearing Roimanager;
	rois=roiManager("count");
	if (rois!=0) {
		roiManager("Deselect");
		roiManager("Delete");
	}
	setTool("Polygon");
	Roisave();
	run ("Close All");
}	

//This function helps on drawing Rois
function Roisave(){
	selectWindow(name);
	do{
		do {
			waitForUser("Please, draw ONE ROI and click OK when finish");
			if (selectionType()!=-1) roiManager("Add");
			rois=roiManager("count");
			if (rois>1) beep();	
			} while (rois>1);	
		if (rois==0){
			beep();
			ok=getBoolean ("YOU DID NOT DRAW ANY ROI, Do you want to SKIP this image?");
			if (ok==true) File.rename(dir+name, dirNP+name); 
		}
		if (rois==1){
			roiManager("Select", 0);
			ok=getBoolean("Do you want to use this ROI?");
			if (ok==true){
				File.rename(dir+name, dirP+name);
				roiManager("Deselect");
				roiManager("Save", dirRoi+name+".zip"); 
			}
			if (ok!=true) {
				roiManager("Deselect");
				roiManager("Delete");
			}
		}
		
	}while (ok!=true);
	if (rois!=0) {
		roiManager("Deselect");
		roiManager("Delete");
	}
}