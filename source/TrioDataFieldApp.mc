//**********************************************************************
// DESCRIPTION : Application for data field for Trio
// AUTHORS :
// Created by ivalkou - https://github.com/ivalkou
// Modify by Pierre Lagarde - https://github.com/avouspierre
// Modified to display IOB with blue drop icon instead of delta
// COPYRIGHT : (c) 2023 ivalkou / Lagarde
//
import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Background;
import Toybox.Time;
import Toybox.System;
import Toybox.Communications;
import Toybox.Graphics;

(:background)
class TrioDataFieldApp extends Application.AppBase {
    var inBackground=false;
    
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
        //register for temporal events if they are supported
        if(Toybox.System has :ServiceDelegate) {
            Background.registerForTemporalEvent(new Time.Duration(5 * 60));
            if (Background has :registerForPhoneAppMessageEvent) {
                Background.registerForPhoneAppMessageEvent();
                System.println("****background is ok****");
            } else {
                System.println("****registerForPhoneAppMessageEvent is not available****");
            }
        } else {
            System.println("****background not available on this device****");
        }
        
        // Create test data with new structure (timestamp in milliseconds)
        var now = Time.now().value();
        var fourMinutesAgo = now - (4 * 60);
        var lastLoopDateMs = fourMinutesAgo.toLong() * 1000;
        
        var sampleData = {
            "date" => lastLoopDateMs,
            "sgv" => 202,
            "delta" => 7,
            "direction" => "DoubleUp",
            "units_hint" => "mmol",
            "iob" => 0.1,
            "cob" => 20.0,
            "eventualBG" => 235,
            "isf" => 100,
            //"sensRatio" => 0.5
        } as Dictionary;
        
        //uncomment for testing
        Application.Storage.setValue("status", sampleData);
    }

    function onBackgroundData(data) {
        if (data instanceof Number || data == null) {
            System.println("Not a dictionary");
        } else {
            System.println("try to update the status");
            if (Background has :registerForPhoneAppMessageEvent) {
                System.println("updated with registerForPhoneAppMessageEvent");
            } else {
                System.println("update status");
                Application.Storage.setValue("status", data as Dictionary);
                Background.registerForTemporalEvent(new Time.Duration(5 * 60));
            }
        }
        System.println("requestUpdate");
        WatchUi.requestUpdate();
    }

    function onStop(state as Dictionary?) as Void {
        if(!inBackground) {
            System.println("stop temp event");
            Background.deleteTemporalEvent();
        }
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new TrioDataFieldView() ] as [Views];
    }

    function getServiceDelegate() {
        inBackground=true;
        System.println("start background");
        return [new TrioBGServiceDelegate()];
    }
}

function getApp() as TrioDataFieldApp {
    return Application.getApp() as TrioDataFieldApp;
}