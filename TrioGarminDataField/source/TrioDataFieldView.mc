//**********************************************************************
// DESCRIPTION : DataField for Trio
// AUTHORS :
//          Created by ivalkou - https://github.com/ivalkou
//          Modify by Pierre Lagarde - https://github.com/avouspierre
// COPYRIGHT : (c) 2023 ivalkou / Lagarde
//

import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;


class TrioDataFieldView extends WatchUi.DataField {

    function initialize() {
        DataField.initialize();
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
// Modified onLayout function with proper vertical alignment
function onLayout(dc as Dc) as Void {
    var obscurityFlags = DataField.getObscurityFlags();

    // Top left quadrant so we'll use the top left layout
    if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT)) {
        View.setLayout(Rez.Layouts.TopLeftLayout(dc));

    // Top right quadrant so we'll use the top right layout
    } else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT)) {
        View.setLayout(Rez.Layouts.TopRightLayout(dc));

    // Bottom left quadrant so we'll use the bottom left layout
    } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT)) {
        View.setLayout(Rez.Layouts.BottomLeftLayout(dc));

    // Bottom right quadrant so we'll use the bottom right layout
    } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {
        View.setLayout(Rez.Layouts.BottomRightLayout(dc));

    // Use the generic, centered layout
    } else {
        View.setLayout(Rez.Layouts.MainLayout(dc));
        
        // Get screen dimensions for percentage calculations
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        var centerX = screenWidth / 2;
        var centerY = screenHeight / 2;
        
        // Get font heights to calculate proper alignment
        var largeFont = Graphics.FONT_SYSTEM_LARGE;
        var smallFont = Graphics.FONT_SYSTEM_SMALL;
        var xtinyFont = Graphics.FONT_SYSTEM_XTINY;
        
        // Calculate font heights
        var largeFontHeight = dc.getFontHeight(largeFont);
        var smallFontHeight = dc.getFontHeight(smallFont);
        var xtinyFontHeight = dc.getFontHeight(xtinyFont);
        
        // Define two baseline Y positions - moved higher to use space better
        var firstLineBaseY = centerY - (screenHeight * 0.35);   // Moved up from 0.15
        var secondLineBaseY = centerY + (screenHeight * 0.05);  // Moved up from 0.15  
        
        // Calculate Y positions to align all text baselines
        // Use the largest font as reference and adjust others relative to it
        var largeBaseline = firstLineBaseY;
        var xtinyAdjustment = (largeFontHeight - xtinyFontHeight) / 2;  // Center smaller fonts
        var smallAdjustment = (largeFontHeight - smallFontHeight) / 2;
        
        // FIRST LINE - 60 centered, BG and arrow close but allowing for max width
        var labelView = View.findDrawableById("label");  // "BG" - XTINY font
        // Position BG to accommodate max width "266" - calculate text width and offset accordingly
        var maxBGWidth = dc.getTextWidthInPixels("266", xtinyFont);
        labelView.locX = centerX - maxBGWidth - (screenWidth * 0.04); // Small gap from "60"
        labelView.locY = largeBaseline + xtinyAdjustment;
        
        var valueView = View.findDrawableById("value");   // "60" - LARGE font (centered)
        valueView.locX = centerX;  // Exactly centered
        valueView.locY = largeBaseline;
        
        var valueViewArrow = View.findDrawableById("arrow");  // Arrow - Bitmap
        // Position arrow close to the right of "60" 
        var valueWidth = dc.getTextWidthInPixels("999", largeFont); // Max expected width
        valueViewArrow.locX = centerX + (valueWidth / 2) + (screenWidth * 0.02); // Small gap from "60"
        valueViewArrow.locY = largeBaseline + (largeFontHeight / 2) - (largeFontHeight * 0.2); // Center with text middle
        
        // SECOND LINE - Use same alignment logic
        var secondLineLargestHeight = smallFontHeight; // Largest font on second line
        var secondLineBaseline = secondLineBaseY;
        var secondXtinyAdjustment = (secondLineLargestHeight - xtinyFontHeight) / 2;
        
        var valueViewDelta = View.findDrawableById("valueDelta");  // "-20" - SMALL font
        valueViewDelta.locX = centerX - (screenWidth * 0.30);     
        valueViewDelta.locY = secondLineBaseline;
        
        var valueViewTime = View.findDrawableById("valueTime");   // "(5m)" - XTINY font
        valueViewTime.locX = centerX - (screenWidth * 0.10);     
        valueViewTime.locY = secondLineBaseline + secondXtinyAdjustment;
        
        var valueViewAiSRIcon = View.findDrawableById("aiSRIcon"); // Green icon - Bitmap
        valueViewAiSRIcon.locX = centerX + (screenWidth * 0.03);  
        valueViewAiSRIcon.locY = secondLineBaseline + (smallFontHeight / 2) - (smallFontHeight * 0.2);
        
        var valueViewAiSR = View.findDrawableById("valueAiSR");   // "2.66" - SMALL font
        valueViewAiSR.locX = centerX + (screenWidth * 0.20);     
        valueViewAiSR.locY = secondLineBaseline;
    }

    (View.findDrawableById("label") as Text).setText(Rez.Strings.label);
}

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
        }

function onUpdate(dc as Dc) as Void {
    var bgString;
    var loopColor;
    var loopString;
    var deltaString;
    var aiSRString;
    var iobString;
    var status = Application.Storage.getValue("status") as Dictionary;

    if (status == null) {
        bgString = "---";
        loopColor = getLoopColor(-1);
        loopString = "(xx)";
        deltaString = "??";
        aiSRString = "??";
        iobString = "??";
    } else {
        var bg = status["glucose"] as String;
        bgString = (bg == null) ? "--" : bg as String;
        var min = getMinutes(status);
        loopColor = getLoopColor(min);
        loopString = (min < 0 ? "(--)" : "(" + min.format("%d")) + "m)" as String;
        deltaString = getDeltaText(status) as String;
        aiSRString = getAiSRText(status) as String;
        iobString = getIOBText(status) as String;
    }

    // Dynamic positioning adjustment for main layout only
    var obscurityFlags = DataField.getObscurityFlags();
    if (obscurityFlags == 0) { // Main layout
        var screenWidth = dc.getWidth();
        var centerX = screenWidth / 2;
        var largeFont = Graphics.FONT_SYSTEM_LARGE;
        var xtinyFont = Graphics.FONT_SYSTEM_XTINY;
        
        // Calculate actual glucose value width and adjust BG and arrow positions
        var currentValueWidth = dc.getTextWidthInPixels(bgString, largeFont);
        var maxBGWidth = dc.getTextWidthInPixels("BG", xtinyFont);
        
        // Update BG position based on actual glucose value width
        var labelView = View.findDrawableById("label");
        labelView.locX = centerX - (currentValueWidth / 2) - maxBGWidth - (screenWidth * 0.02);
        
        // Update arrow position based on actual glucose value width  
        var valueViewArrow = View.findDrawableById("arrow");
        valueViewArrow.locX = centerX + (currentValueWidth / 2) + (screenWidth * 0.02);
    }

    // Set the background color
    (View.findDrawableById("Background") as Text).setColor(loopColor);
    
    // Set the foreground color and value
    var value = View.findDrawableById("value") as Text;
    var valueTime = View.findDrawableById("valueTime") as Text;
    var valueDelta = View.findDrawableById("valueDelta") as Text;
    var valueAiSR = View.findDrawableById("valueAiSR") as Text;
    if (getBackgroundColor() == Graphics.COLOR_BLACK) {
        value.setColor(Graphics.COLOR_WHITE);
        valueTime.setColor(Graphics.COLOR_WHITE);
        valueDelta.setColor(Graphics.COLOR_WHITE);
        valueAiSR.setColor(Graphics.COLOR_WHITE);
    } else {
        value.setColor(Graphics.COLOR_BLACK);
        valueTime.setColor(Graphics.COLOR_BLACK);
        valueDelta.setColor(Graphics.COLOR_BLACK);
        valueAiSR.setColor(Graphics.COLOR_BLACK);
    }
    value.setText(bgString);
    valueDelta.setText(deltaString);
    valueTime.setText(loopString);
    valueAiSR.setText(aiSRString);

    var arrowView = View.findDrawableById("arrow") as Bitmap;
    var aiSRIconView = View.findDrawableById("aiSRIcon") as Bitmap;
    
    if (getBackgroundColor() == Graphics.COLOR_BLACK) {
         arrowView.setBitmap(getDirection(status));
         if (aiSRIconView != null) {
             aiSRIconView.setBitmap(WatchUi.loadResource(Rez.Drawables.aiSRDark));
         }
    }
    else {
        arrowView.setBitmap(getDirectionBlack(status));
        if (aiSRIconView != null) {
            aiSRIconView.setBitmap(WatchUi.loadResource(Rez.Drawables.aiSRLight));
        }
    }
    // Call parent's onUpdate(dc) to redraw the layout
    View.onUpdate(dc);
}

    function getMinutes(status) as Number {

        if (status instanceof Dictionary)  {
            var lastLoopDate = status["lastLoopDateInterval"] as Number;
            if (lastLoopDate == null) {
                return -1;
            }
            var now = Time.now().value() as Number;
            // Calculate seconds difference
            var deltaSeconds = now - lastLoopDate;
            // Round up to the nearest minute if delta is positive
            var min = (deltaSeconds > 0) ? ((deltaSeconds + 59) / 60) : 0;
            return min;
        } else {
            return -1;
        }
    }

    function getLoopColor(min as Number) as Number {
        if (min < 0) {
            return getBackgroundColor() as Number;
        } else if (min <= 5) {
            return getBackgroundColor() as Number;
        } else if (min <= 10) {
            return Graphics.COLOR_YELLOW as Number;
        } else {
            return Graphics.COLOR_RED as Number;
        }
    }

    function getDeltaText(status as Dictionary) as String {
        // var status = Application.Storage.getValue("status") as Dictionary;
        if (status == null) {
            return "--";
        }
        var delta = status["delta"] as String;
        var deltaString = (delta == null) ? "--" : delta;
        return deltaString;
    }

    function getAiSRText(status as Dictionary) as String {
        // var status = Application.Storage.getValue("status") as Dictionary;
        if (status == null) {
            return "--";
        }
        var aiSR = status["aiSR"] as String;
        var aiSRString = (aiSR == null) ? "--" : aiSR;
        return aiSRString;
    }

    function getIOBText(status as Dictionary) as String {
        // var status = Application.Storage.getValue("status") as Dictionary;
        if (status == null) {
            return "--";
        }
        var iob = status["iob"] as String;
        var iobString = (iob == null) ? "--" : iob;
        return iobString;
    }

    function getDirectionBlack(status) as BitmapType {
        var bitmap = WatchUi.loadResource(Rez.Drawables.UnknownB);
        if (status instanceof Dictionary)  {
            var trend = status["trendRaw"] as String;
            if (trend == null) {
                return bitmap;
            }
            switch (trend) {
                case "Flat":
                    bitmap = WatchUi.loadResource(Rez.Drawables.FlatB);
                    break;
                case "SingleUp":
                    bitmap = WatchUi.loadResource(Rez.Drawables.SingleUpB);
                    break;
                case "SingleDown":
                    bitmap = WatchUi.loadResource(Rez.Drawables.SingleDownB);
                    break;
                case "FortyFiveUp":
                    bitmap = WatchUi.loadResource(Rez.Drawables.FortyFiveUpB);
                    break;
                case "FortyFiveDown":
                    bitmap = WatchUi.loadResource(Rez.Drawables.FortyFiveDownB);
                    break;
                case "DoubleUp":
                case "TripleUp":
                    bitmap = WatchUi.loadResource(Rez.Drawables.DoubleUpB);
                    break;
                case "DoubleDown":
                case "TripleDown":
                    bitmap = WatchUi.loadResource(Rez.Drawables.DoubleDownB);
                    break;
                default: break;
            }

            return bitmap;
        } else {
            return bitmap;
        }

    }

    function getDirection(status) as BitmapType {
        var bitmap = WatchUi.loadResource(Rez.Drawables.Unknown);
        if (status instanceof Dictionary)  {
            var trend = status["trendRaw"] as String;
            if (trend == null) {
                return bitmap;
            }

            switch (trend) {
                case "Flat":
                    bitmap = WatchUi.loadResource(Rez.Drawables.Flat);
                    break;
                case "SingleUp":
                    bitmap = WatchUi.loadResource(Rez.Drawables.SingleUp);
                    break;
                case "SingleDown":
                    bitmap = WatchUi.loadResource(Rez.Drawables.SingleDown);
                    break;
                case "FortyFiveUp":
                    bitmap = WatchUi.loadResource(Rez.Drawables.FortyFiveUp);
                    break;
                case "FortyFiveDown":
                    bitmap = WatchUi.loadResource(Rez.Drawables.FortyFiveDown);
                    break;
                case "DoubleUp":
                case "TripleUp":
                    bitmap = WatchUi.loadResource(Rez.Drawables.DoubleUp);
                    break;
                case "DoubleDown":
                case "TripleDown":
                    bitmap = WatchUi.loadResource(Rez.Drawables.DoubleDown);
                    break;
                default: break;
            }

            return bitmap;
        } else {
            return bitmap;
        }
    }
}