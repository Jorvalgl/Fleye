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
Dialog.addMessage("FLEYE comes with ABSOLUTELY NO WARRANTY; click on help button for details.");
Dialog.setInsets(0, 20, 0);
Dialog.addMessage("This is free software, and you are welcome to redistribute it under certain conditions; click on help button for details.");
Dialog.addHelp("http://www.gnu.org/licenses/gpl.html");
Dialog.show();

//This macro open a menu to execute diverse FLEYE macros


items=newArray ("ROIs design", "Parameter optimization", "Analysis", "Exit");
do{
	html="<html>"+"<h2>FLEYE HELP</h2>"
	+"<font size=+1>"
	+"Please check the following reference for help:<br><br>"
	+"Reference<br><br>"
	+"You can also contact us: jorge.valero@cnc.uc.pt";
	Dialog.create("FLEYE");
	Dialog.addRadioButtonGroup("Please, select an option:", items, 3, 4, "ROIs design");
	//Dialog.addChoice("Please, select an option", items);
	Dialog.addHelp(html);
	Dialog.show();
	option= Dialog.getRadioButton;
	sure=getBoolean("You have selected: -"+option+"- do you want to proceed?");
	if (sure==true){
		if (option=="ROIs design") run("Fleye ROISv1.2");
		if (option=="Parameter optimization") run("Fleye optimizer v4.3");
		if (option=="Analysis") run("Fleye v10.5");
	}
	else if (option=="Exit") option="bu";
} while (option!="Exit");

