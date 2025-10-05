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

        // Dynamic positioning: adjust BG and arrow based on glucose value width
        var screenWidth = dc.getWidth();
        var centerX = screenWidth / 2;
        var largeFont = Graphics.FONT_SYSTEM_LARGE;
        var xtinyFont = Graphics.FONT_SYSTEM_XTINY;
        
        // Calculate actual glucose value width
        var currentValueWidth = dc.getTextWidthInPixels(bgString, largeFont);
        
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
        var valueViewIOBUnit = View.findDrawableById("valueIOBUnit");
        var valueViewEventualBG = View.findDrawableById("valueEventualBG");
        
        // Define margins
        var leftMargin = 0.08;
        var rightMargin = 0.08;

        // LEFT SIDE: IOB value left-aligned with "U" right after
        if (valueViewIOB != null && valueViewIOBUnit != null) {
            var iobTextWidth = dc.getTextWidthInPixels(iobString, largeFont);
            var iobStartX = screenWidth * leftMargin;
            
            // IOB value left-aligned
            valueViewIOB.locX = iobStartX;
            valueViewIOB.setJustification(Graphics.TEXT_JUSTIFY_LEFT);
            
            // "U" unit positioned right after IOB number
            valueViewIOBUnit.locX = iobStartX + iobTextWidth + 2;
            valueViewIOBUnit.setJustification(Graphics.TEXT_JUSTIFY_LEFT);
            
            // Adjust vertical position to align baselines
            var largeHeight = dc.getFontHeight(largeFont);
            var xtinyHeight = dc.getFontHeight(xtinyFont);
            valueViewIOBUnit.locY = valueViewIOB.locY + (largeHeight - xtinyHeight) * 0.8;
        }

        // Handle right side - either sensRatio with icon or COB with "g" unit
        var valueViewAiSRIcon = View.findDrawableById("aiSRIcon");
        var valueViewAiSR = View.findDrawableById("valueAiSR");
        var valueViewAiSRUnit = View.findDrawableById("valueAiSRUnit");

        if (showingSensRatio) {
            // Position sensRatio with icon on the right
            if (valueViewAiSRIcon != null && valueViewAiSR != null && valueViewAiSRUnit != null) {
                var sensRatioTextWidth = dc.getTextWidthInPixels(rightSideString, largeFont);
                var rightEdgeX = screenWidth * (1 - rightMargin);
                
                // sensRatio text right-aligned at right margin
                valueViewAiSR.locX = rightEdgeX;
                valueViewAiSR.setJustification(Graphics.TEXT_JUSTIFY_RIGHT);
                
                // Icon positioned to the left of the text
                valueViewAiSRIcon.locX = rightEdgeX - sensRatioTextWidth - (screenWidth * 0.07);
                
                // Hide the unit label for sensRatio
                valueViewAiSRUnit.locX = -100;
            }
        } else {
            // RIGHT SIDE: COB value right-aligned with "g" right after
            if (valueViewAiSRIcon != null && valueViewAiSR != null && valueViewAiSRUnit != null) {
                // RIGHT SIDE: COB value with "g" at right margin (92%)
                var cobTextWidth = dc.getTextWidthInPixels(rightSideString, largeFont);
                var gUnitWidth = dc.getTextWidthInPixels("g", xtinyFont);
                var rightEdgeX = screenWidth * (1 - rightMargin);

                // Hide the icon
                valueViewAiSRIcon.locX = -100;

                // "g" unit positioned AT the right margin (92%)
                valueViewAiSRUnit.locX = rightEdgeX - gUnitWidth;
                valueViewAiSRUnit.setJustification(Graphics.TEXT_JUSTIFY_LEFT);

                // COB value positioned to the LEFT of "g"
                valueViewAiSR.locX = rightEdgeX - gUnitWidth - 2;
                valueViewAiSR.setJustification(Graphics.TEXT_JUSTIFY_RIGHT);

                // Adjust vertical position to align baselines
                var largeHeight = dc.getFontHeight(largeFont);
                var xtinyHeight = dc.getFontHeight(xtinyFont);
                valueViewAiSRUnit.locY = valueViewAiSR.locY + (largeHeight - xtinyHeight) * 0.7;
            }
        }

        // Dynamically position eventual BG centered between IOB and COB/sensRatio
        if (valueViewEventualBG != null && valueViewIOB != null && valueViewIOBUnit != null) {
            // Calculate the right edge of IOB+unit
            var iobTextWidth = dc.getTextWidthInPixels(iobString, largeFont);
            var iobUnitWidth = dc.getTextWidthInPixels("U", xtinyFont);
            var iobRightEdge = (screenWidth * leftMargin) + iobTextWidth + 2 + iobUnitWidth;
            
            // Calculate left edge of right side element
            var rightSideLeftEdge;
            if (showingSensRatio && valueViewAiSRIcon != null) {
                rightSideLeftEdge = valueViewAiSRIcon.locX;
            } else {
                var cobTextWidth = dc.getTextWidthInPixels(rightSideString, largeFont);
                rightSideLeftEdge = screenWidth * (1 - rightMargin) - cobTextWidth;
            }
            
            // Center the eventual BG
            valueViewEventualBG.locX = (iobRightEdge + rightSideLeftEdge) / 2;
        }

        // Set background color and text values
        (View.findDrawableById("Background") as Text).setColor(loopColor);
        
        var value = View.findDrawableById("value") as Text;
        var valueEventualBG = View.findDrawableById("valueEventualBG") as Text;
        var valueAiSR = View.findDrawableById("valueAiSR") as Text;
        var valueIOB = View.findDrawableById("valueIOB") as Text;
        var valueIOBUnit = View.findDrawableById("valueIOBUnit") as Text;
        var valueAiSRUnit = View.findDrawableById("valueAiSRUnit") as Text;
        var bgLabel = View.findDrawableById("label") as Text;
        
// Check if background is RED or YELLOW
    var backgroundIsRed = (loopColor == Graphics.COLOR_RED);
    var backgroundIsYellow = (loopColor == Graphics.COLOR_YELLOW);
    
    if (backgroundIsRed) {
        // RED background - force all text to WHITE for contrast (regardless of dark/light mode)
        if (bgLabel != null) {
            bgLabel.setColor(Graphics.COLOR_WHITE);
        }
        value.setColor(Graphics.COLOR_WHITE);
        valueEventualBG.setColor(Graphics.COLOR_WHITE);
        
        if (valueIOB != null && valueIOBUnit != null) {
            valueIOB.setColor(Graphics.COLOR_WHITE);
            valueIOBUnit.setColor(Graphics.COLOR_WHITE);
        }
        
        if (showingSensRatio) {
            valueAiSR.setColor(Graphics.COLOR_WHITE);
        } else {
            valueAiSR.setColor(Graphics.COLOR_WHITE);
            valueAiSRUnit.setColor(Graphics.COLOR_WHITE);
        }
    } else if (getBackgroundColor() == Graphics.COLOR_BLACK) {
        // Black background - use light/bright colors
        if (bgLabel != null) {
            bgLabel.setColor(Graphics.COLOR_GREEN);
        }
        value.setColor(Graphics.COLOR_WHITE);
        valueEventualBG.setColor(Graphics.COLOR_WHITE);
        
        // IOB color
        if (valueIOB != null && valueIOBUnit != null) {
            if (backgroundIsYellow) {
                valueIOB.setColor(Graphics.COLOR_WHITE);
                valueIOBUnit.setColor(Graphics.COLOR_WHITE);
            } else {
                valueIOB.setColor(Graphics.COLOR_BLUE);
                valueIOBUnit.setColor(Graphics.COLOR_BLUE);
            }
        }
        
        // Right side color
        if (showingSensRatio) {
            valueAiSR.setColor(Graphics.COLOR_WHITE);
        } else {
            // COB
            if (backgroundIsYellow) {
                valueAiSR.setColor(Graphics.COLOR_WHITE);
                valueAiSRUnit.setColor(Graphics.COLOR_WHITE);
            } else {
                valueAiSR.setColor(Graphics.COLOR_YELLOW);
                valueAiSRUnit.setColor(Graphics.COLOR_YELLOW);
            }
        }
    } else {
        // White background - use dark colors
        if (bgLabel != null) {
            bgLabel.setColor(Graphics.COLOR_DK_GREEN);
        }
        value.setColor(Graphics.COLOR_BLACK);
        valueEventualBG.setColor(Graphics.COLOR_BLACK);
        
        // IOB color
        if (valueIOB != null && valueIOBUnit != null) {
            if (backgroundIsYellow) {
                valueIOB.setColor(Graphics.COLOR_BLACK);
                valueIOBUnit.setColor(Graphics.COLOR_BLACK);
            } else {
                valueIOB.setColor(Graphics.COLOR_DK_BLUE);
                valueIOBUnit.setColor(Graphics.COLOR_DK_BLUE);
            }
        }
        
        // Right side color
        if (showingSensRatio) {
            valueAiSR.setColor(Graphics.COLOR_BLACK);
        } else {
            // COB
            if (backgroundIsYellow) {
                valueAiSR.setColor(Graphics.COLOR_BLACK);
                valueAiSRUnit.setColor(Graphics.COLOR_BLACK);
            } else {
                valueAiSR.setColor(Graphics.COLOR_ORANGE);
                valueAiSRUnit.setColor(Graphics.COLOR_ORANGE);
            }
        }
    }
        
        value.setText(bgString);
        valueEventualBG.setText(evBGString);
        valueAiSR.setText(rightSideString);
        if (valueIOB != null) {
            valueIOB.setText(iobString);
        }
        if (valueIOBUnit != null) {
            valueIOBUnit.setText("U");
        }
        if (valueAiSRUnit != null) {
            if (showingSensRatio) {
                valueAiSRUnit.setText("");  // No unit for sensRatio
            } else {
                valueAiSRUnit.setText("g");  // Show "g" for COB
            }
        }

        // Set icon bitmaps
        var arrowView = View.findDrawableById("arrow") as Bitmap;
        var aiSRIconView = View.findDrawableById("aiSRIcon") as Bitmap;
        
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            arrowView.setBitmap(getDirection(status));
            if (aiSRIconView != null && showingSensRatio) {
                aiSRIconView.setBitmap(WatchUi.loadResource(Rez.Drawables.aiSRDark));
            }
        } else {
            arrowView.setBitmap(getDirectionBlack(status));
            if (aiSRIconView != null && showingSensRatio) {
                aiSRIconView.setBitmap(WatchUi.loadResource(Rez.Drawables.aiSRLight));
            }
        }
        
        View.onUpdate(dc);
    }

    // Keep these functions returning just numbers (no units)
    function getCOBText(status as Dictionary) as String {
        if (status == null) {
            return "--";
        }
        var cob = status["cob"];
        if (cob == null) {
            return "--";
        }
        if (cob instanceof Number) {
            return cob.format("%3.1f");
        } else {
            return cob.toString();
        }
    }

    function getIOBText(status as Dictionary) as String {
        if (status == null) {
            return "--";
        }
        var iob = status["iob"];
        if (iob == null) {
            return "--";
        }
        if (iob instanceof Number) {
            return iob.format("%2.1f");
        } else {
            return iob.toString();
        }
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

    function getSensRatioText(status as Dictionary) as String {
        if (status == null) {
            return "--";
        }
        var sensRatio = status["sensRatio"] as String;
        var sensRatioString = (sensRatio == null) ? "--" : sensRatio;
        return sensRatioString;
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