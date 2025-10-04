//**********************************************************************
// DESCRIPTION : DataField for Trio
// AUTHORS :
//          Created by ivalkou - https://github.com/ivalkou
//          Modify by Pierre Lagarde - https://github.com/avouspierre
//          Added IOB support with blue drop icon (delta code preserved)
// COPYRIGHT : (c) 2023 ivalkou / Lagarde
//

import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;


class TrioDataFieldView extends WatchUi.DataField {

    private var isBottomPosition = false;

    function initialize() {
        DataField.initialize();
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
    }

    function onLayout(dc as Dc) as Void {
        var obscurityFlags = DataField.getObscurityFlags();
        
        // Check if top is obscured (meaning we're in bottom position)
        // But we need to REVERSE the layout assignment
        // When OBSCURE_TOP is set, we're in bottom position but need MainLayout (short first line)
        // When OBSCURE_TOP is not set, we're in top position but need BottomLayout (short second line)
        if ((obscurityFlags & OBSCURE_TOP) != 0) {
            // Bottom position - use MainLayout (first line is shorter)
            isBottomPosition = true;
            View.setLayout(Rez.Layouts.MainLayout(dc));
        } else {
            // Top position - use BottomLayout (second line is shorter)
            isBottomPosition = false;
            View.setLayout(Rez.Layouts.BottomLayout(dc));
        }

        (View.findDrawableById("label") as Text).setText(Rez.Strings.label);
    }

    function onUpdate(dc as Dc) as Void {
        var bgString;
        var loopColor;
        var evBGString;
        var rightSideString;  // Either sensRatio or COB
        var showingSensRatio = false;
        var iobString;
        var status = Application.Storage.getValue("status") as Dictionary;

        if (status == null) {
            bgString = "---";
            loopColor = getLoopColor(-1);
            evBGString = "(---)";
            rightSideString = "??";
            iobString = "??";
        } else {
            var bg = status["glucose"] as String;
            bgString = (bg == null) ? "--" : bg as String;
            var min = getMinutes(status);
            loopColor = getLoopColor(min);
            // Get eventualBGRaw from status
            var evBG = status["eventualBGRaw"] as String;
            evBGString = "(" + ((evBG == null) ? "--" : evBG) + ")" as String;
            
            // Check for sensRatio first, then COB
            var sensRatio = status["sensRatio"];
            var cob = status["cob"];
            
            if (sensRatio != null) {
                rightSideString = getSensRatioText(status) as String;
                showingSensRatio = true;
            } else if (cob != null) {
                rightSideString = getCOBText(status) as String;
                showingSensRatio = false;
            } else {
                rightSideString = "??";
                showingSensRatio = false;
            }
            
            iobString = getIOBText(status) as String;
        }

        // ONLY dynamic positioning: adjust BG and arrow based on glucose value width
        var screenWidth = dc.getWidth();
        var centerX = screenWidth / 2;
        var largeFont = Graphics.FONT_SYSTEM_LARGE;
        var xtinyFont = Graphics.FONT_SYSTEM_XTINY;
        
        // Calculate actual glucose value width
        var currentValueWidth = dc.getTextWidthInPixels(bgString, largeFont);
        var maxBGWidth = dc.getTextWidthInPixels("BG", xtinyFont);
        
        // Adjust BG and arrow positions dynamically
        var labelView = View.findDrawableById("label");
        if (labelView != null) {
            labelView.locX = centerX - (currentValueWidth / 2) - (screenWidth * 0.07);
        }
        
        var valueViewArrow = View.findDrawableById("arrow");
        if (valueViewArrow != null) {
            valueViewArrow.locX = centerX + (currentValueWidth / 2) + (screenWidth * 0.03);
        }

        // Dynamic positioning for second line: IOB icon, IOB value, time, aiSR icon, aiSR value
        var valueViewIOBIcon = View.findDrawableById("iobIcon");
        var valueViewIOB = View.findDrawableById("valueIOB");
        var valueViewTime = View.findDrawableById("valueTime");

        // Position IOB value: half its width + 3% right of IOB icon
        if (valueViewIOBIcon != null && valueViewIOB != null) {
            // Calculate IOB text width with LARGE font
            var iobTextWidth = dc.getTextWidthInPixels(iobString, Graphics.FONT_SYSTEM_LARGE);

            // Position IOB value: icon position + half text width + 3% spacing
            valueViewIOB.locX = valueViewIOBIcon.locX + (iobTextWidth / 2) + (screenWidth * 0.07);
        }

        // Handle right side - either sensRatio with icon or COB without icon
        var valueViewAiSRIcon = View.findDrawableById("aiSRIcon");
        var valueViewAiSR = View.findDrawableById("valueAiSR");

        if (showingSensRatio) {
            // Position aiSR icon 0.07 left of aiSR value 
            if (valueViewAiSRIcon != null && valueViewAiSR != null) {
                // Calculate sensRatio text width with LARGE font
                var sensRatioTextWidth = dc.getTextWidthInPixels(rightSideString, Graphics.FONT_SYSTEM_LARGE);

                // Position sensRatio icon relative to the text's left edge (accounting for right justification)
                valueViewAiSRIcon.locX = (screenWidth * 0.92) - sensRatioTextWidth - (screenWidth * 0.07);
            }
        } else {
            // COB - hide the icon by moving it off screen
            if (valueViewAiSRIcon != null) {
                valueViewAiSRIcon.locX = -100; // Move off screen
            }
        }

        // Dynamically position loop time (valueTime) centered between IOB value and right side
        if (valueViewTime != null && valueViewIOB != null) {
            // Calculate the right edge of IOB value with LARGE font
            var iobTextWidth = dc.getTextWidthInPixels(iobString, Graphics.FONT_SYSTEM_LARGE);
            var iobRightEdge = valueViewIOB.locX + (iobTextWidth / 2);
            
            // For positioning, use either icon left edge or COB text left edge
            var rightSideLeftEdge;
            if (showingSensRatio && valueViewAiSRIcon != null) {
                rightSideLeftEdge = valueViewAiSRIcon.locX;
            } else {
                // For COB, calculate where the text starts (right-aligned at 92%)
                var cobTextWidth = dc.getTextWidthInPixels(rightSideString, Graphics.FONT_SYSTEM_LARGE);
                rightSideLeftEdge = (screenWidth * 0.92) - cobTextWidth;
            }
            
            // Center the time string between these two points
            valueViewTime.locX = (iobRightEdge + rightSideLeftEdge) / 2;
        }

        // Set background color and text values
        (View.findDrawableById("Background") as Text).setColor(loopColor);
        
        var value = View.findDrawableById("value") as Text;
        var valueTime = View.findDrawableById("valueTime") as Text;
        var valueAiSR = View.findDrawableById("valueAiSR") as Text;
        var valueIOB = View.findDrawableById("valueIOB") as Text;
        
        // Cast labelView as Text for color setting
        var bgLabel = View.findDrawableById("label") as Text;
        
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            // Black background - use light/bright colors
            if (bgLabel != null) {
                bgLabel.setColor(Graphics.COLOR_GREEN);  // Bright green matching aiSRDark
            }
            value.setColor(Graphics.COLOR_WHITE);
            valueTime.setColor(Graphics.COLOR_WHITE);
            valueAiSR.setColor(Graphics.COLOR_WHITE);  // White for both sensRatio and COB
            if (valueIOB != null) {
                valueIOB.setColor(Graphics.COLOR_WHITE);
            }
        } else {
            // White background - use dark colors
            if (bgLabel != null) {
                bgLabel.setColor(Graphics.COLOR_DK_GREEN);  // Dark green matching aiSRLight (008000)
            }
            value.setColor(Graphics.COLOR_BLACK);
            valueTime.setColor(Graphics.COLOR_BLACK);
            valueAiSR.setColor(Graphics.COLOR_BLACK);  // Black for both sensRatio and COB
            if (valueIOB != null) {
                valueIOB.setColor(Graphics.COLOR_BLACK);
            }
        }
        
        value.setText(bgString);
        valueTime.setText(evBGString);
        valueAiSR.setText(rightSideString);  // Sets either sensRatio or COB
        if (valueIOB != null) {
            valueIOB.setText(iobString);
        }

        // Set icon bitmaps
        var arrowView = View.findDrawableById("arrow") as Bitmap;
        var aiSRIconView = View.findDrawableById("aiSRIcon") as Bitmap;
        var iobIconView = View.findDrawableById("iobIcon") as Bitmap;
        
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            arrowView.setBitmap(getDirection(status));
            if (aiSRIconView != null && showingSensRatio) {
                aiSRIconView.setBitmap(WatchUi.loadResource(Rez.Drawables.aiSRDark));
            }
            if (iobIconView != null) {
                iobIconView.setBitmap(WatchUi.loadResource(Rez.Drawables.iobLight));
            }
        }
        else {
            arrowView.setBitmap(getDirectionBlack(status));
            if (aiSRIconView != null && showingSensRatio) {
                aiSRIconView.setBitmap(WatchUi.loadResource(Rez.Drawables.aiSRLight));
            }
            if (iobIconView != null) {
                iobIconView.setBitmap(WatchUi.loadResource(Rez.Drawables.iobDark));
            }
        }
        
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

    function getCOBText(status as Dictionary) as String {
        if (status == null) {
            return "--";
        }
        var cob = status["cob"];
        if (cob == null) {
            return "--";
        }
        // Format COB with "g" suffix
        if (cob instanceof Number) {
            return cob.format("%3.1f") + "g";
        } else {
            return cob.toString() + "g";
        }
    }

    function getSensRatioText(status as Dictionary) as String {
        if (status == null) {
            return "--";
        }
        var sensRatio = status["sensRatio"] as String;
        var sensRatioString = (sensRatio == null) ? "--" : sensRatio;
        return sensRatioString;
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