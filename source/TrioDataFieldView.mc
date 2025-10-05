//**********************************************************************
// DESCRIPTION : DataField for Trio
// AUTHORS :
//          Created by ivalkou - https://github.com/ivalkou
//          Modify by Pierre Lagarde - https://github.com/avouspierre
//          IOB displayed as text with U suffix (icon removed)
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

         // Dynamic positioning for second line: IOB value, eventual BG, sensRatio/COB
        var valueViewIOB = View.findDrawableById("valueIOB");
        var valueViewEventualBG = View.findDrawableById("valueEventualBG");
        
        // Define margins as parameters for consistency
        var leftMargin = 0.08;  // 8% margin for left-aligned IOB text
        var rightMargin = 0.08; // 8% margin for right-aligned text (92% = 100% - 8%)

        // Position IOB value at the left edge with margin
        if (valueViewIOB != null) {
            valueViewIOB.locX = screenWidth * leftMargin; // Using parameter
            valueViewIOB.setJustification(Graphics.TEXT_JUSTIFY_LEFT);
        }

        // Handle right side - either sensRatio with icon or COB without icon
        var valueViewAiSRIcon = View.findDrawableById("aiSRIcon");
        var valueViewAiSR = View.findDrawableById("valueAiSR");

        if (showingSensRatio) {
            // Position sensRatio icon to the left of sensRatio value 
            if (valueViewAiSRIcon != null && valueViewAiSR != null) {
                // Calculate sensRatio text width with LARGE font
                var sensRatioTextWidth = dc.getTextWidthInPixels(rightSideString, Graphics.FONT_SYSTEM_LARGE);

                // Position icon 7% left of the right-aligned text
                valueViewAiSRIcon.locX = screenWidth * (1 - rightMargin) - sensRatioTextWidth - (screenWidth * 0.07);
            }
        } else {
            // COB - hide the icon by moving it off screen
            if (valueViewAiSRIcon != null) {
                valueViewAiSRIcon.locX = -100; // Move off screen
            }
        }

        // Dynamically position eventual BG centered between IOB and right side
        if (valueViewEventualBG != null && valueViewIOB != null) {
            // Calculate the right edge of IOB value
            var iobTextWidth = dc.getTextWidthInPixels(iobString, Graphics.FONT_SYSTEM_LARGE);
            var iobRightEdge = (screenWidth * leftMargin) + iobTextWidth; // Using parameter
            
            // Calculate left edge of right side element
            var rightSideLeftEdge;
            if (showingSensRatio && valueViewAiSRIcon != null) {
                // Use sensRatio icon position
                rightSideLeftEdge = valueViewAiSRIcon.locX;
            } else {
                // For COB, calculate where the text starts
                var cobTextWidth = dc.getTextWidthInPixels(rightSideString, Graphics.FONT_SYSTEM_LARGE);
                rightSideLeftEdge = screenWidth * (1 - rightMargin) - cobTextWidth;
            }
            
            // Center the eventual BG between IOB and right side
            valueViewEventualBG.locX = (iobRightEdge + rightSideLeftEdge) / 2;
        }

        // Set background color and text values
        (View.findDrawableById("Background") as Text).setColor(loopColor);
        
        var value = View.findDrawableById("value") as Text;
        var valueEventualBG = View.findDrawableById("valueEventualBG") as Text;
        var valueAiSR = View.findDrawableById("valueAiSR") as Text;
        var valueIOB = View.findDrawableById("valueIOB") as Text;
        
        // Cast labelView as Text for color setting
        var bgLabel = View.findDrawableById("label") as Text;
        
        // Check if background is colored (yellow/red) due to loop status
        var backgroundColored = (loopColor == Graphics.COLOR_YELLOW || loopColor == Graphics.COLOR_RED);
        
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            // Black background - use light/bright colors
            if (bgLabel != null) {
                bgLabel.setColor(Graphics.COLOR_GREEN);  // Bright green matching aiSRDark
            }
            value.setColor(Graphics.COLOR_WHITE);
            valueEventualBG.setColor(Graphics.COLOR_WHITE);
            
            // IOB color - blue unless background is colored
            if (valueIOB != null) {
                if (backgroundColored) {
                    valueIOB.setColor(Graphics.COLOR_WHITE);
                } else {
                    valueIOB.setColor(Graphics.COLOR_BLUE);
                }
            }
            
            // Right side (sensRatio or COB) color
            if (showingSensRatio) {
                valueAiSR.setColor(Graphics.COLOR_WHITE);  // White for sensRatio
            } else {
                // COB - yellow unless background is colored
                if (backgroundColored) {
                    valueAiSR.setColor(Graphics.COLOR_WHITE);
                } else {
                    valueAiSR.setColor(Graphics.COLOR_YELLOW);
                }
            }
        } else {
            // White background - use dark colors
            if (bgLabel != null) {
                bgLabel.setColor(Graphics.COLOR_DK_GREEN);  // Dark green matching aiSRLight (008000)
            }
            value.setColor(Graphics.COLOR_BLACK);
            valueEventualBG.setColor(Graphics.COLOR_BLACK);
            
            // IOB color - blue unless background is colored
            if (valueIOB != null) {
                if (backgroundColored) {
                    valueIOB.setColor(Graphics.COLOR_BLACK);
                } else {
                    valueIOB.setColor(Graphics.COLOR_DK_BLUE);
                }
            }
            
            // Right side (sensRatio or COB) color
            if (showingSensRatio) {
                valueAiSR.setColor(Graphics.COLOR_BLACK);  // Black for sensRatio
            } else {
                // COB - dark yellow/orange unless background is colored
                if (backgroundColored) {
                    valueAiSR.setColor(Graphics.COLOR_BLACK);
                } else {
                    valueAiSR.setColor(Graphics.COLOR_ORANGE);  // Orange (dark yellow) for visibility on white
                }
            }
        }
        
        value.setText(bgString);
        valueEventualBG.setText(evBGString);
        valueAiSR.setText(rightSideString);  // Sets either sensRatio or COB
        if (valueIOB != null) {
            valueIOB.setText(iobString);
        }

        // Set icon bitmaps
        var arrowView = View.findDrawableById("arrow") as Bitmap;
        var aiSRIconView = View.findDrawableById("aiSRIcon") as Bitmap;
        
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            arrowView.setBitmap(getDirection(status));
            if (aiSRIconView != null && showingSensRatio) {
                aiSRIconView.setBitmap(WatchUi.loadResource(Rez.Drawables.aiSRDark));
            }
        }
        else {
            arrowView.setBitmap(getDirectionBlack(status));
            if (aiSRIconView != null && showingSensRatio) {
                aiSRIconView.setBitmap(WatchUi.loadResource(Rez.Drawables.aiSRLight));
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
        if (status == null) {
            return "--";
        }
        var iob = status["iob"];
        if (iob == null) {
            return "--";
        }
        // Format IOB with "U" suffix like in watchface
        if (iob instanceof Number) {
            return iob.format("%2.1f") + "U";
        } else {
            return iob.toString() + "U";
        }
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