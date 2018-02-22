macro "les bacteries de Marine"{
//OpenFile
Pathdata = File.openDialog("Select the file");
	Dirdata = File.getParent(Pathdata);
	Namedata = File.getName(Pathdata);
	Namedata_withoutExtension = File.nameWithoutExtension;
	print(Pathdata);
	print(Dirdata);
	print(Namedata);
	Worked_Data_Path = Dirdata+"\\"+Namedata_withoutExtension+File.separator;
print(Worked_Data_Path);
File.makeDirectory(Worked_Data_Path);
run("Bio-Formats", "open="+Pathdata+" autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");

Nmb=3;
ThrLow = 3;
ThrHigh = 254;
Dialog.create("Data Extraction");
  //Dialog.addNumber("Number of images to remove from max ", Nmb);
  Dialog.addNumber("Seuillage minimum ", ThrLow);
  Dialog.addNumber("Seuillage maxnimum ", ThrHigh);
  Dialog.addCheckbox("Correction",true);
  Dialog.addCheckbox("Binning 2",true);
  Dialog.show();
  Nmb = Dialog.getNumber();
  CorrectionState = Dialog.getCheckbox();
	binningState = Dialog.getCheckbox();
getDimensions(width, height, channels, slices, frames);
print (width);
NmbSlices = slices;
Data_Binned_path = Worked_Data_Path+Namedata+"_1024.tif";
print(Data_Binned_path);
BinnedImageExist = File.exists(Data_Binned_path);
print(BinnedImageExist);
if (binningState == true && BinnedImageExist == 1){
	close(Namedata);
	run("Bio-Formats", "open="+Data_Binned_path+" autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
}
if (binningState == true && BinnedImageExist == 0){
	run("Size...", "width=1024 height=1024 depth=&NmbSlices constrain average");
	Data_Binned_path= Worked_Data_Path+Namedata+"_1024.tif";
	saveAs("Tiff", Data_Binned_path);}
	
run("Enhance Contrast", "saturated=0.35");
rename(Namedata);
selectWindow(Namedata);
IntensityArr = newArray(0);
Maxi = newArray(0);
run("Set Measurements...", "mean redirect=None decimal=3");

//Select Most intense slice and substack
setBatchMode(true);
for (n=1; n<=nSlices; n++) {
          setSlice(n);
          run("Measure");
          Intensity = getResult('Mean');	
		  IntensityArr = append(IntensityArr, Intensity);
      }
Array.show(IntensityArr);
Maxi = Array.findMaxima(IntensityArr, 0);
Array.show(Maxi);
setBatchMode(false);
selectWindow("Maxi");
IJ.renameResults("Results");
SliceMax = getResult("Value",0)+1;
//print(SliceMax);
selectWindow(Namedata);
setSlice(SliceMax);
Slicestart = SliceMax;
Sliceend = nSlices;
run("Make Substack...", "slices="+Slicestart+"-"+Sliceend);
	 	
//Correction by array done on Syto9
if (CorrectionState == true){
run("32-bit");
pathfile=File.openDialog("Choose the file to Open:"); 
filestring=File.openAsString(pathfile); 
print(filestring);
rows=split(filestring, "\n"); 
IntensityCorrec=newArray(rows.length); 
for(i=0; i<rows.length; i++){ 
columns=split(rows[i],"\t"); 
IntensityCorrec[i]=parseFloat(columns[0]); 
} 
lengthofArray = IntensityCorrec.length;
lengthofStack = nSlices;
IntensityCorrecSized=Array.trim(IntensityCorrec, nSlices);
Array.show(IntensityCorrecSized);
print(lengthofArray);
print(lengthofStack);
setBatchMode(true);
if (lengthofStack < lengthofArray) {
	for(i=0; i<lengthofStack; i++) {
		setSlice(i+1);
		ValueCorrec=IntensityCorrecSized[i];
		print(ValueCorrec);
		run("Divide...", "value=&ValueCorrec slice");
	}
}	
if (lengthofStack >= lengthofArray) {
	for(i=0; i<lengthofArray; i++) {
		setSlice(i+1);
		ValueCorrec=IntensityCorrecSized[i];
		print(ValueCorrec);
		run("Divide...", "value=&ValueCorrec slice");
	}
}
setBatchMode(false);
Data_Corrected_Binned_path= Worked_Data_Path+Namedata+"Corrected_1024.tif";
	saveAs("Tiff", Data_Corrected_Binned_path);
	}
//} //to save corrected 1024 image stack file and quit macro
rename("Substack");
//Measure Area, Average for area selected by thresholding...
run("Set Measurements...","area mean integrated redirect=None decimal=3");
setAutoThreshold("Otsu dark");
//setBatchMode(true);
for (n=1; n<=nSlices; n++) {
          setSlice(n);
          setThreshold(ThrLow,ThrHigh);
          run("Create Mask");
          rename("Mask"+n);
          selectWindow("Substack");
      }
//setBatchMode(false);
run("Images to Stack", "name=StackMask title=Mask use");
run("Divide...", "value=255 stack");
//Create StackMask shifted by 1 slice
run("Duplicate...", "duplicate range=2-"+nSlices);
setSlice(nSlices);
run("Add Slice");
//Adding two StackMasks 
imageCalculator("Add create stack", "StackMask","StackMask-1");
rename("Stack_SUM");
run("Subtract...", "value=1 stack");
run("Multiply...", "value=2 stack");
//Substracting two StackMasks
imageCalculator("Substract create stack", "StackMask","StackMask-1");
rename("Stack_SUBS");
//Adding Two stacks for Stack with connectivity information
imageCalculator("Add create stack", "Stack_SUM","Stack_SUBS");
rename("Stack_Connect_1");
//rename("Connectivitymap3D.tif");
close("Stack_Sum");
close("Stack_SUBS");
close("StackMask");
close("StackMask-1");
//Remove ends of stack
run("Z Project...", "projection=[Sum Slices]");

SUM_Connect_path = Worked_Data_Path+"SUM_Connect.tif";
saveAs("Tiff", SUM_Connect_path);
//Criterion of highness (to improve)
	 Dialog.create("Segmentation Selection");
	items =newArray("Manual", "RATS", "Sobel");
   Dialog.addRadioButtonGroup("Segmentation Options", items, 1, 3, "One") 
  Dialog.show;
   Option = Dialog.getRadioButton;
   print("Segmentation: "+Option);
//OPtion1 Manual Threshold on Connectivity map
if(Option == "Manual"){
	Nmb_Connect = 3;
	run("Threshold...");
	title = "Select Connectivity";
  msg = "Use the \"Threshold\" tool to\nadjust the connectivity criterion, then click \"OK\".";
  waitForUser(title, msg);
  getThreshold(lower, upper);
  Nmb_Connect = round(lower);	
run("Analyze Particles...", "size=100-Infinity display include add in_situ");
ROIcount =roiManager("count");
roiManager("Save", Worked_Data_Path+"\\SetROIColonies_C"+Nmb_Connect+".zip");

selectWindow("SUM_Connect.tif");
run("Duplicate...", "SUM_Connect-1.tif");
waitForUser("Pause");
setBatchMode(true);
for(i=0; i<=ROIcount-1;i++){
	selectWindow("SUM_Connect-1.tif");
	roiManager("Select",i);
	getRawStatistics(nPixels, mean, min, max, std, histogram);
	maxC = max;
	minC = min;
	diffC = maxC- minC;
	selectWindow("SUM_Connect-1.tif");
	run("Subtract...", "value="+minC);
	run("Divide...", "value="+diffC);
	run("Multiply...","value="+16);
	run("Add...", "value="+16*(i+1));
}
setBatchMode(false);
run("16 colors");
SUM_Connect_path2 = Worked_Data_Path+"SUM_Connect_Colored_C"+Nmb_Connect+".tif";
saveAs("Tiff", SUM_Connect_path2);
}
//End of option 1
//option2 Threshold by RATS
if(Option == "RATS"){
run("Robust Automatic Threshold Selection", "noise=1 lambda=3 min=205");
run("Analyze Particles...", "size=150-Infinity display include add in_situ");
ROIcount =roiManager("count");
roiManager("Save", Worked_Data_Path+"\\SetROIColonies_C_RATS.zip");
selectWindow("SUM_Connect-mask");
rename("SUM_Connect.tif");

selectWindow("SUM_Connect.tif");
run("Duplicate...", "SUM_Connect-1.tif");
setBatchMode(true);
for(i=0; i<=ROIcount-1;i++){
	selectWindow("SUM_Connect-1.tif");
	roiManager("Select",i);
	getRawStatistics(nPixels, mean, min, max, std, histogram);
	maxC = max;
	minC = min;
	diffC = maxC- minC;
	selectWindow("SUM_Connect-1.tif");
	run("Subtract...", "value="+minC);
	run("Divide...", "value="+diffC);
	run("Multiply...","value="+16);
	run("Add...", "value="+16*(i+1));
}
setBatchMode(false);
run("16 colors");
waitForUser("looksgood");
SUM_Connect_path2 = Worked_Data_Path+"SUM_Connect_Colored_RATS.tif";
saveAs("Tiff", SUM_Connect_path2);
}
//end of option 2
if(Option == "Sobel"){
selectWindow("SUM_Connect.tif");
setBatchMode(true);
run("Duplicate...", " ");
rename("Vert");
//Kernel 5
run("Convolve...", "text1=[2 1 0 -1 -2\n3 2 0 -2 -3\n4 3 0 -3 -4\n3 2 0 -2 -3\n2 1 0 -1 -2\n] normalize");

//Kernel 3
//run("Convolve...", "text1=[-10 0 10\n-3 0 3\n-10 0 10\n] normalize");
selectWindow("SUM_Connect.tif");
run("Duplicate...", " ");
rename("Hori");
//Kernel 5
run("Convolve...", "text1=[2 3 4 3 2\n1 2 3 2 1\n0 0 0 0 0\n-1 -2 -3 -2 -1\n-2 -3 -4 -3 -2\n] normalize");
//Kernel 3
//run("Convolve...", "text1=[-10 -3 -10\n0 0 0\n10 3 10\n] normalize"
imageCalculator("Multiply create 32-bit", "Hori","Hori");
rename("Hori2");
imageCalculator("Multiply create 32-bit", "Vert","Vert");
rename("Vert2");
imageCalculator("Add create 32-bit", "Hori2","Vert2");
rename("Gradient");
close("Hori");close("Vert");close("Hori2");close("Vert2");
imageCalculator("Multiply create 32-bit", "Gradient","SUM_Connect.tif");
imageCalculator("Multiply create 32-bit", "Result of Gradient","SUM_Connect.tif");
rename("Weighted");
close("Result of Gradient");
setAutoThreshold("MinError dark");
run("Make Binary");
run("Close-");
run("Fill Holes");
setBatchMode(false);
//color the colonies
run("Analyze Particles...", "size=100-Infinity display include add in_situ");
ROIcount =roiManager("count");
//roiManager("Save", Worked_Data_Path+"\\SetROIColonies_C_Sobel.zip");
for(i=0; i<=ROIcount-1;i++){
	selectWindow("Weighted");
	roiManager("Select",i);
	getRawStatistics(nPixels, mean, min, max, std, histogram);
	maxC = max;
	minC = min;
	diffC = maxC- minC;
	selectWindow("Weighted");
	run("Subtract...", "value="+maxC);
	run("Add...", "value="+1*(i+1));
}
run("16 colors");
waitForUser("looksgood");
SUM_Connect_path2 = Worked_Data_Path+"SUM_Connect_Colored_Sobel.tif";
saveAs("Tiff", SUM_Connect_path2);
}

	


//setBatchMode(true);
for(i=0; i<=ROIcount-1;i++){
	//Crop Different section of the Mask
	selectWindow("SUM_Connect.tif");
	roiManager("Select",i);
	run("Enlarge...", "enlarge=1");
	roiManager("Add");
	roiManager("Select",i+ROIcount);
	selectWindow("Substack");
	roiManager("Select",i+ROIcount);
	titleSubstack_ROI = "objects_ROI"+i;
	run("Duplicate...", "duplicate");
	rename("objects_ROI"+i);
	run("Create Mask");
	run("Divide...", "value=255");
	rename("Massk_ROI"+i);
	selectWindow("Stack_Connect_1");
	roiManager("Select",i+ROIcount);
	titleSubstack_ROI = "Connect_ROI"+i;
	run("Duplicate...", "duplicate");
	rename(titleSubstack_ROI);


//Crop Stack_Connect with Mask_ROI
	selectWindow("Stack_Connect_1");
	roiManager("Select",i+ROIcount);
	Stack_Connect_MASK_ROI="MASK_ROI_"+i;
	Subsstack_Mask_Roi="Substack_"+i;
	imageCalculator("Multiply create stack", "objects_ROI"+i,"Massk_ROI"+i);
	rename(Subsstack_Mask_Roi);
	imageCalculator("Multiply create stack", "Connect_ROI"+i,"Massk_ROI"+i);
	rename(Stack_Connect_MASK_ROI);
	close("Massk_ROI"+i);
	close("objects_ROI"+i);
	close("Connect_ROI"+i);
}
//setBatchMode(false);
roiManager("Save", Worked_Data_Path+"\\SetROIColoniesE_"+Option+".zip");
close("Substack");
close("Stack_Connect_1");
close(Namedata);
//More Precise
run("Clear Results");
Nmb_Size = 1;
Dialog.create("Size Criterion");
  Dialog.addNumber("Size ", Nmb_Size);
	Dialog.show();
  Nmb_Size = Dialog.getNumber();
  setBatchMode(true);
for (j=0; j<=ROIcount-1;j++){
	roiManager("Select All");
	roiManager("Delete");
	selectWindow("Substack_"+j);
	setThreshold(1,255);
	for (l=1; l<=nSlices; l++){
		 	setSlice(l);
		 	Counter=l;
		 	run("Select All");
		 	run("Analyze Particles...", "size=&Nmb_Size-Infinity include add slice");
		 	CountRoi=roiManager("count");
		 	print(CountRoi);
		 	//List of temporary elements
		 	ArrayRoiTemp= newArray(0);
		 	for (n=Counter;n<=CountRoi; n++){
		 	ArrayRoiTemp= append(ArrayRoiTemp, -1+n);
		 	}
		 	Array.show(ArrayRoiTemp);
		 	roiManager("select", ArrayRoiTemp);
		 	run("Clear Results");
		 	size=ArrayRoiTemp.length;
		 	if (size==1) {
		 		roiManager("Add");
		 		roiManager("select", ArrayRoiTemp);
		 		roiManager("Delete");
		 	}
		 	if (size>=2) { 
		 		roiManager("Combine");
		 		roiManager("Add");
		 		roiManager("select", ArrayRoiTemp);
		 		roiManager("Delete");
		 	}	 	
	}
	CountRoi_MaskROI=roiManager("count");
	roiManager("select",CountRoi_MaskROI-1 );
		 		roiManager("Delete");
	selectWindow("Substack_"+j);
run("Set Measurements...", "area perimeter redirect=None decimal=3");
	CountRoi_MaskROI=roiManager("count");
	for (l=0; l<=CountRoi_MaskROI-1; l++){
	roiManager("Select",l);
	roiManager("Measure");
	}
	selectWindow("Results");
	IJ.renameResults("Results_NONFILTERED_"+j);

	//StackMask
			roiManager("Select",0);
		 	run("Create Mask");
		 	rename("StackMask"+j);
		 	selectWindow("Substack_"+j);
	for (l=2; l<=CountRoi_MaskROI; l++){
		    selectWindow("Substack_"+j);
		 	setSlice(l);
		 	roiManager("Select",l-1);
		 	run("Create Mask");
		 	rename("Mask_"+l);
		 	run("Copy");
		 	selectWindow("StackMask"+j);
		 	run("Add Slice");
		 	setSlice(l);
		 	run("Paste");
		 	close("Mask_"+l);
		 	selectWindow("Substack_"+j);
		 	}
	selectWindow("Substack_"+j); 
	NmbSlice = nSlices;	
	print(NmbSlice);
	if(CountRoi_MaskROI <= NmbSlice){
		for (l=CountRoi_MaskROI; l<=NmbSlice-1; l++){
			selectWindow("StackMask"+j);
		 	run("Add Slice");
		}
	}
	//CreateSubStack without the Nmb_Size
	selectWindow("StackMask"+j);
	run("Divide...", "value=255 stack");
	
imageCalculator("Multiply create stack", "StackMask"+j,"Substack_"+j);
rename("SubstackCleaned"+j);
	CountRoi_MaskROI=roiManager("count");
	print(CountRoi_MaskROI);
	selectWindow("SubstackCleaned"+j);
	var exitloop = false;
	for (k=0; k<=CountRoi_MaskROI-1 && !exitloop; k++){
			print(k);		
			roiManager("Select",k);	
				roiManager("Measure");
				MeanTemp = getResult("Mean",k);
			if (MeanTemp == 0) { 
                exitloop = true; 
       		 } 
       		 else { 
           setThreshold(1,200);
		 	run("Create Selection");
		 	roiManager("Add");
		 	} 
		
	}
	selectWindow("Results");
	run("Close");
	ArrayRoiTemp2= newArray(0);
		 	for (n=0;n<=CountRoi_MaskROI-1; n++){
		 	ArrayRoiTemp2= append(ArrayRoiTemp2,n);
		 	}
		 	Array.show(ArrayRoiTemp2);
		 	roiManager("select", ArrayRoiTemp2);
		 	roiManager("Delete");
				CountRoi_MaskROI=roiManager("count");
		run("Set Measurements...", "area mean perimeter integrated redirect=None decimal=3");
	for (l=0; l<=CountRoi_MaskROI-1; l++){
	roiManager("Select",l);
	roiManager("Measure");
	}
	roiManager("Save", Worked_Data_Path+"\\SetROIMask"+j+"_"+Option+"_S"+Nmb_Size+".zip");	selectWindow("Results");
	IJ.renameResults("Results_"+j);

}
setBatchMode(false);
run("Tile");
roiManager("Select All");
roiManager("Delete");
}


//Extend the array size and Add a value 
function append(array, value) {
	 array2 = newArray(array.length+1);
     	 for (i=0; i<array.length; i++)
         array2[i]=array[i];
     	 array2[array.length]=value;
     	 return array2;
}





function NewArrayName(Name,ArrayName) {
	 Name = ArrayName;
	 ArrayName = newArray(0);
	 }