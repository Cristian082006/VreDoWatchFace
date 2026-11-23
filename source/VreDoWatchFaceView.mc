using Toybox.ActivityMonitor;
using Toybox.Application;
using Toybox.Application.WatchFaceConfig;
using Toybox.Complications;
using Toybox.Graphics;
using Toybox.Math;
using Toybox.Position;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.UserProfile;
using Toybox.WatchUi;
using Toybox.Weather;

class VreDoWatchFaceView extends WatchUi.WatchFace {
    var mEditMode = false;
    var mLowPower = false;
    var mValueFont = null;
    var mCompactFont = null;
    var mSmallFont = null;
    var mTempFont = null;
    var mTimeFont = null;
    var mDateFont = null;
    var mDialFont = null;
    var mLocationFont = null;
    var mMetricFonts = null;
    var mBaseFonts = null;
    var mBaseFontSizes = null;
    var mScaledFonts = null;
    var mCurrentScale = null;
    var mWeatherCache = null;
    var mWeatherRefreshTimer = null;
    var mPositionCache = null;
    var mIsSmallDevice = false;
    var mScreenScale = 1.0;
    var mConfiguredComplications = [null, null, null, null, null, null];
    var mUseConfiguredComplications = false;
    var mComplicationCallbackRegistered = false;
    var mSelectedComplicationIdentifier = null;

    function initialize(editMode) {
        WatchFace.initialize();
        mEditMode = editMode;
        var faces = ["RobotoCondensedBold", "RobotoBold", "RobotoCondensedRegular", "RobotoRegular"];
        mValueFont = Graphics.getVectorFont({:face => faces, :size => 38});
        mCompactFont = mValueFont;
        mSmallFont = Graphics.getVectorFont({:face => faces, :size => 32});
        mTempFont = Graphics.getVectorFont({:face => faces, :size => 70});
        mTimeFont = Graphics.getVectorFont({:face => faces, :size => 116});
        mDateFont = Graphics.getVectorFont({:face => faces, :size => 38});
        mDialFont = Graphics.getVectorFont({:face => faces, :size => 66});
        mLocationFont = Graphics.getVectorFont({:face => faces, :size => 38});
        mMetricFonts = [
            mValueFont,
            Graphics.getVectorFont({:face => faces, :size => 34}),
            Graphics.getVectorFont({:face => faces, :size => 30}),
            Graphics.getVectorFont({:face => faces, :size => 26}),
            Graphics.getVectorFont({:face => faces, :size => 22}),
            Graphics.getVectorFont({:face => faces, :size => 20}),
            Graphics.getVectorFont({:face => faces, :size => 18}),
            Graphics.getVectorFont({:face => faces, :size => 16})
        ];
        mBaseFonts = [mValueFont, mSmallFont, mTempFont, mTimeFont, mDateFont, mDialFont, mLocationFont,
                      mMetricFonts[0], mMetricFonts[1], mMetricFonts[2], mMetricFonts[3],
                      mMetricFonts[4], mMetricFonts[5], mMetricFonts[6], mMetricFonts[7]];
        mBaseFontSizes = [38, 32, 70, 116, 38, 66, 38, 38, 34, 30, 26, 22, 20, 18, 16];
    }

    function onEnterSleep() { mLowPower = true; }
    function onExitSleep() { mLowPower = false; }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var side = w < h ? w : h;
        mIsSmallDevice = side <= 260;
        var scale = side / 454.0;
        mScreenScale = scale;
        var drawDc = dc;
        if (scale < 0.999) {
            if (mCurrentScale == null || mCurrentScale != scale) {
                mScaledFonts = [];
                var faces = ["RobotoCondensedBold", "RobotoBold", "RobotoCondensedRegular", "RobotoRegular"];
                for (var i = 0; i < mBaseFontSizes.size(); i += 1) {
                    var scaledSize = Math.round(mBaseFontSizes[i] * scale);
                    if (scaledSize < 1) { scaledSize = 1; }
                    mScaledFonts.add(Graphics.getVectorFont({:face => faces, :size => scaledSize}));
                }
                mCurrentScale = scale;
            }
            drawDc = new ScaledWatchFaceDc(dc, scale, mBaseFonts, mScaledFonts);
            w = 454;
            h = 454;
        }
        var cx = w / 2;
        var cy = h / 2;
        var clock = System.getClockTime();
        var weather = getWeatherSnapshot();

        drawAnalogFace(drawDc, cx, cy, clock, weather, mLowPower);
    }

    // Garmin supplies a cached weather snapshot; reread it every five minutes when the
    // watchface gets an update. The provider itself controls when that cache is refreshed.
    function getWeatherSnapshot() {
        var timer = System.getTimer();
        if (mWeatherRefreshTimer == null || timer < mWeatherRefreshTimer || timer - mWeatherRefreshTimer >= 300000) {
            mWeatherCache = Weather.getCurrentConditions();
            var positionInfo = Position.getInfo();
            mPositionCache = positionInfo == null ? null : positionInfo.position;
            mWeatherRefreshTimer = timer;
        }
        return mWeatherCache;
    }

    function drawAnalogFace(dc, cx, cy, clock, weather, lowPower) {
        var face = lowPower ? Graphics.COLOR_BLACK : 0x07090B;
        var ink = lowPower ? 0x777D82 : 0xF2F4F5;
        var accent = lowPower ? 0x777D82 : 0xD6B641;
        dc.setColor(face, face);
        dc.clear();
        dc.setColor(lowPower ? 0x45494C : 0x30363B, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, 219);
        dc.drawCircle(cx, cy, 207);

        // Move the minute track inward to clear a larger outer ring for the numerals.
        for (var i = 0; i < 60; i += 1) {
            // The date box replaces the three o'clock hour marker.
            if (i == 15) { continue; }
            var angle = (i * 6 - 90) * Math.PI / 180.0;
            var inner = i % 5 == 0 ? 159 : 168;
            var x1 = cx + Math.cos(angle) * inner;
            var y1 = cy + Math.sin(angle) * inner;
            var x2 = cx + Math.cos(angle) * 177;
            var y2 = cy + Math.sin(angle) * 177;
            dc.setColor(i % 5 == 0 ? accent : (lowPower ? 0x55595D : 0x667078), Graphics.COLOR_TRANSPARENT);
            dc.drawLine(x1, y1, x2, y2);
        }
        drawDialNumbers(dc, cx, cy, ink);
        drawDateBox(dc, lowPower, ink, accent);

        // Keep hand endpoints ready, then draw the hands over the information below.
        var minuteAngle = (clock.min * 6 - 90) * Math.PI / 180.0;
        var hourAngle = (((clock.hour % 12) + clock.min / 60.0) * 30 - 90) * Math.PI / 180.0;
        var minuteX = cx + Math.cos(minuteAngle) * 143;
        var minuteY = cy + Math.sin(minuteAngle) * 143;
        var hourX = cx + Math.cos(hourAngle) * 91;
        var hourY = cy + Math.sin(hourAngle) * 91;
        var seconds = System.getClockTime().sec;
        var secondAngle = (seconds * 6 - 90) * Math.PI / 180.0;
        var digitalTimeEnabled = settingBoolean("showDigitalTime", false);

        var monitor = ActivityMonitor.getInfo();
        var heartRate = latestHeartRate();
        var stats = System.getSystemStats();
        drawWeatherCenter(dc, cx, 154, weather, lowPower, ink, accent);
        drawWeatherDetails(dc, weather, lowPower, ink);
        drawNextSunEvent(dc, weather, lowPower, ink);
        drawBottomMetrics(dc, lowPower, ink);
        drawBottomLocation(dc, weather, lowPower, ink);
        if (!digitalTimeEnabled) {
            dc.setColor(lowPower ? 0x777D82 : 0xD7D9E1, Graphics.COLOR_TRANSPARENT);
            drawThickLine(dc, cx, cy, hourX, hourY, 5);
            drawThickLine(dc, cx, cy, minuteX, minuteY, 4);
            if (!mIsSmallDevice) {
                dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
                drawThickLine(dc, cx, cy, cx + Math.cos(secondAngle) * 157, cy + Math.sin(secondAngle) * 157, 2);
            }
        }
        if (digitalTimeEnabled) {
            var digital = clock.hour.format("%02d") + ":" + clock.min.format("%02d");
            dc.setColor(lowPower ? ink : accent, Graphics.COLOR_TRANSPARENT);
            dc.drawText(76, 240, mDateFont, digital, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        if (!digitalTimeEnabled) {
            dc.setColor(accent, accent);
            dc.fillCircle(cx, cy, lowPower ? 2 : 4);
        }
    }

    function drawDialNumbers(dc, cx, cy, color) {
        var numbers = ["12", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"];
        var radius = 190;
        for (var i = 0; i < numbers.size(); i += 1) {
            if (i == 3) { continue; }
            var angle = (i * 30 - 90) * Math.PI / 180.0;
            var x = cx + Math.cos(angle) * radius;
            var y = cy + Math.sin(angle) * radius;
            drawText(dc, x, y, numbers[i], mDialFont, color);
        }
    }

    function drawMiniMetric(dc, x, y, icon, text, iconColor, textColor, lowPower) {
        // Keep the small metrics visually open: icons and values sit directly on the dial.
        drawMetricValue(dc, x + 3, y, 94, 46, icon, text, textColor, iconColor);
    }

    function drawBottomMetrics(dc, lowPower, color) {
        var monitor = ActivityMonitor.getInfo();
        var heartRate = latestHeartRate();
        var altitude = latestElevation();
        var stats = System.getSystemStats();
        var activeMinutes = monitor.activeMinutesWeek;
        var weeklyMinutes = activeMinutes == null ? "--m" : activeMinutes.total.format("%d") + "m";
        var icons = [0, 1, 5, 4, 7, 6, 2, 2, 3, 3, 6, 2, 4, 0, 5, 5, 7, 7, 3, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 3, 5, 5];
        var forecast = Weather.getDailyForecast();
        var low = forecast != null && forecast.size() > 0 && forecast[0] != null ? forecast[0].lowTemperature : null;
        var high = forecast != null && forecast.size() > 0 && forecast[0] != null ? forecast[0].highTemperature : null;
        var current = getWeatherSnapshot();
        if (low == null && current != null) { low = current.lowTemperature; }
        if (high == null && current != null) { high = current.highTemperature; }
        var wind = current == null ? null : current.windSpeed;
        var solar = nextSunEvent(current);
        var pressure = current == null ? null : current.pressure;
        var uv = current == null ? null : current.uvIndex;
        var cloud = current == null ? null : current.cloudCover;
        var visibility = current == null ? null : current.visibility;
        var values = [grouped(monitor.steps), value(heartRate, "--") + "bpm", altitude == null ? "--" : altitude.format("%d") + "m", grouped(activeCalories(monitor.calories)), weeklyMinutes, stats.battery.format("%d") + "%", value(current == null ? null : current.temperature, "--") + "°", value(low, "--") + "/" + value(high, "--") + "°", value(current == null ? null : current.precipitationChance, "--") + "%", wind == null ? "--km/h" : (wind * 3.6).format("%d") + "km/h", value(current == null ? null : current.relativeHumidity, "--") + "%", solar[:time], value(monitor.calories, "--") + "kcal", monitor.distance == null ? "--m" : (monitor.distance / 1000).format("%d") + "km", value(monitor.floorsClimbed, "--"), value(monitor.floorsClimbedGoal, "--"), monitor.activeMinutesDay == null ? "--m" : monitor.activeMinutesDay.total.format("%d") + "m", value(monitor.moveBarLevel, "--"), value(monitor.respirationRate, "--") + "br", value(monitor.stressScore, "--"), value(monitor.timeToRecovery, "--") + "m", value(current == null ? null : current.feelsLikeTemperature, "--") + "°", value(current == null ? null : current.dewPoint, "--") + "°", value(uv, "--") + " UV", value(pressure, "--") + "hPa", value(cloud, "--") + "%", visibility == null ? "--km" : visibility.format("%.1f") + "km", value(current == null ? null : current.windBearing, "--") + "°", value(monitor.stepGoal, "--"), value(monitor.floorsDescended, "--"), value(monitor.metersClimbed, "--") + "m"];
        var keys = ["complication1", "complication2", "complication3", "complication4", "complication5", "complication6"];
        var centers = [136, 227, 318];
        var customComplications = Application.Properties.getValue("useCustomComplications") == true;
        for (var i = 0; i < 6; i += 1) {
            if (mUseConfiguredComplications && !customComplications) {
                drawConfiguredComplication(dc, i, lowPower, color, values, icons);
                continue;
            }
            var selected = settingNumber(keys[i], i + 1);
            if (selected == 0) { continue; }
            var metricIndex = selected - 1;
            if (metricIndex < 0 || metricIndex >= values.size()) { metricIndex = i; }
            var row = i < 3 ? 0 : 1;
            var center = centers[i % 3];
            var y = row == 0 ? 257 : 304;
            var slotWidths = [86, 86, 86];
            drawPackedMetric(dc, center, y + 22, slotWidths[i % 3], icons[metricIndex], values[metricIndex], color, lowPower ? color : metricAccent(icons[metricIndex]));
        }
        drawSelectedComplicationOutline(dc);
    }

    function drawSelectedComplicationOutline(dc) {
        if (mSelectedComplicationIdentifier == null) { return; }
        var index = mSelectedComplicationIdentifier - 1;
        if (index < 0 || index >= 6) { return; }
        var centerX = [136, 227, 318][index % 3];
        var top = index < 3 ? 257 : 304;
        dc.setColor(0xFFD34E, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(centerX - 43, top, 86, 46, 5);
        dc.drawRoundedRectangle(centerX - 41, top + 2, 82, 42, 3);
    }

    function updateComplicationSettings(settings) {
        if (settings == null || settings.complicationSettings == null) {
            mUseConfiguredComplications = false;
            return;
        }
        mConfiguredComplications = [null, null, null, null, null, null];
        var rows = settings.complicationSettings;
        for (var i = 0; i < rows.size(); i += 1) {
            var row = rows[i];
            var identifier = row.uniqueIdentifier;
            if (identifier != null && identifier >= 1 && identifier <= 6) {
                mConfiguredComplications[identifier - 1] = row.complicationId;
            }
        }
        mUseConfiguredComplications = true;
        if (!mEditMode && !mComplicationCallbackRegistered) {
            // Register before subscribing so the initial value update is not missed.
            Complications.registerComplicationChangeCallback(method(:onComplicationChange));
            mComplicationCallbackRegistered = true;
        }
        if (!mEditMode) {
            for (var i = 0; i < mConfiguredComplications.size(); i += 1) {
                var id = mConfiguredComplications[i];
                if (id != null) {
                    try {
                        Complications.subscribeToUpdates(id);
                    } catch (e) {
                        // Some system complication IDs may be unavailable on this device.
                    }
                }
            }
        }
        WatchUi.requestUpdate();
    }

    function onComplicationChange(id as Complications.Id) as Void {
        WatchUi.requestUpdate();
    }

    function drawConfiguredComplication(dc, index, lowPower, color, values, icons) {
        var id = mConfiguredComplications[index];
        if (id == null || id.getType() == Complications.COMPLICATION_TYPE_INVALID) { return; }
        var data = null;
        try {
            data = Complications.getComplication(id);
        } catch (e) {
            return;
        }
        if (data == null) { return; }
        var type = id.getType();
        var metricIndex = configuredMetricIndex(type);
        if (metricIndex >= 0 && metricIndex < values.size()) {
            var centerX = [136, 227, 318][index % 3];
            var centerY = index < 3 ? 279 : 326;
            drawPackedMetric(dc, centerX, centerY, 86, icons[metricIndex], values[metricIndex], color,
                lowPower ? color : metricAccent(icons[metricIndex]));
            return;
        }
        var value = data.value;
        var valueText = value == null ? "" : value.toString();
        var unit = complicationUnit(data.unit);
        if (valueText.length() > 0 && unit.length() > 0) { valueText += unit; }
        if (valueText.length() == 0) { valueText = "--"; }
        var label = data.shortLabel;
        if (label == null || label.length() == 0) { label = data.longLabel; }
        var centerX = [136, 227, 318][index % 3];
        var centerY = index < 3 ? 279 : 326;
        var valueFont = fitTextFont(dc, valueText, 80, mValueFont);
        drawText(dc, centerX, centerY - 6, valueText, valueFont, lowPower ? color : Graphics.COLOR_WHITE);
        if (label != null && label.length() > 0 && label != valueText) {
            var labelFont = fitTextFont(dc, label, 80, mMetricFonts[6]);
            drawText(dc, centerX, centerY + 15, label, labelFont, lowPower ? color : Graphics.COLOR_WHITE);
        }
    }

    // Prefer values from the same device APIs used by the on-watch complication menu.
    function configuredMetricIndex(type) {
        if (type == Complications.COMPLICATION_TYPE_BATTERY) { return 5; }
        if (type == Complications.COMPLICATION_TYPE_STEPS) { return 0; }
        if (type == Complications.COMPLICATION_TYPE_HEART_RATE) { return 1; }
        if (type == Complications.COMPLICATION_TYPE_ALTITUDE) { return 2; }
        if (type == Complications.COMPLICATION_TYPE_CALORIES) { return 3; }
        if (type == Complications.COMPLICATION_TYPE_INTENSITY_MINUTES) { return 4; }
        if (type == Complications.COMPLICATION_TYPE_FLOORS_CLIMBED) { return 14; }
        if (type == Complications.COMPLICATION_TYPE_RECOVERY_TIME) { return 20; }
        if (type == Complications.COMPLICATION_TYPE_STRESS) { return 19; }
        if (type == Complications.COMPLICATION_TYPE_RESPIRATION_RATE) { return 18; }
        if (type == Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE) { return 25; }
        if (type == Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE) { return 6; }
        if (type == Complications.COMPLICATION_TYPE_HIGH_LOW_TEMPERATURE) { return 7; }
        return -1;
    }

    function complicationUnit(unit) {
        if (unit == null) { return ""; }
        if (unit instanceof Lang.String) { return " " + unit; }
        if (unit == Complications.UNIT_DISTANCE) { return "m"; }
        if (unit == Complications.UNIT_ELEVATION) { return "m"; }
        if (unit == Complications.UNIT_HEIGHT) { return "m"; }
        if (unit == Complications.UNIT_SPEED) { return "m/s"; }
        if (unit == Complications.UNIT_TEMPERATURE) { return "°"; }
        if (unit == Complications.UNIT_WEIGHT) { return "g"; }
        return "";
    }

    function complicationBounds(index) {
        var centerX = [136, 227, 318][index % 3];
        var top = index < 3 ? 257 : 304;
        var left = (centerX - 43) * mScreenScale;
        var y = top * mScreenScale;
        var width = 86 * mScreenScale;
        var height = 46 * mScreenScale;
        return [left, y, width, height];
    }

    function getComplicationDrawable(identifier) {
        if (identifier == null || identifier < 1 || identifier > 6) { return null; }
        mSelectedComplicationIdentifier = identifier;
        var bounds = complicationBounds(identifier - 1);
        var drawable = new VreDoComplicationBounds({
            :locX => bounds[0], :locY => bounds[1], :width => bounds[2], :height => bounds[3]
        });
        var box = new Graphics.BoundingBox();
        box.addRectangle(bounds[0].toNumber(), bounds[1].toNumber(), bounds[2].toNumber(), bounds[3].toNumber());
        WatchUi.requestUpdate();
        return new WatchUi.ComplicationDrawableRef({:drawable => drawable, :boundingBox => box});
    }

    function getTappedComplication(x, y) {
        var px = x / mScreenScale;
        var py = y / mScreenScale;
        var centers = [136, 227, 318];
        for (var i = 0; i < 6; i += 1) {
            var left = centers[i % 3] - 43;
            var top = i < 3 ? 257 : 304;
            if (px >= left && px <= left + 86 && py >= top && py <= top + 46) { return i + 1; }
        }
        return null;
    }

    function drawBottomLocation(dc, weather, lowPower, color) {
        var place = weatherLocation(weather);
        var iconColor = lowPower ? color : 0xD5DCE1;
        var slotWidth = 180;
        var iconWidth = 24;
        var gap = 5;
        var selectedFont = fitTextFont(dc, place, slotWidth - iconWidth - gap, mLocationFont);
        var textWidth = dc.getTextWidthInPixels(place, selectedFont);
        var groupWidth = iconWidth + gap + textWidth;
        var groupLeft = 227 - groupWidth / 2;
        drawLocationIcon(dc, groupLeft + iconWidth / 2, 353, iconColor);
        dc.setColor(iconColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(groupLeft + iconWidth + gap, 353, selectedFont, place, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function metricAccent(icon) {
        if (icon == 0 || icon == 4) { return 0xFFB04B; }
        if (icon == 1) { return 0xFF6E73; }
        if (icon == 5) { return 0xA8DDEB; }
        if (icon == 6) { return 0x70D9A0; }
        return 0xD6B641;
    }

    function drawWeatherDetails(dc, weather, lowPower, color) {
        var low = weather == null ? null : weather.lowTemperature;
        var high = weather == null ? null : weather.highTemperature;
        var forecast = Weather.getDailyForecast();
        if (forecast != null && forecast.size() > 0 && forecast[0] != null) {
            if (low == null) { low = forecast[0].lowTemperature; }
            if (high == null) { high = forecast[0].highTemperature; }
        }
        var rain = weather == null ? null : weather.precipitationChance;
        var wind = weather == null ? null : weather.windSpeed;
        var humidity = weather == null ? null : weather.relativeHumidity;
        var windValue = wind == null ? "--" : (wind * 3.6).format("%d");
        var values = [value(low, "--") + "°/" + value(high, "--") + "°", value(rain, "--") + "%", windValue + "km/h", value(humidity, "--") + "%"];
        var positions = [[142, 182], [312, 182], [142, 208], [312, 208]];
        for (var i = 0; i < values.size(); i += 1) {
            var px = positions[i][0];
            var py = positions[i][1];
            var iconColor = lowPower ? color : (i == 0 ? 0xD6B641 : (i == 1 || i == 3 ? 0x72C8EF : 0xA8DDEB));
            drawPackedWeatherDetail(dc, px, py, 126, i, values[i], color, iconColor);
        }
    }

    function drawPackedWeatherDetail(dc, center, y, slotWidth, kind, text, color, iconColor) {
        var iconWidth = 24;
        var gap = 5;
        var selectedFont = fitTextFont(dc, text, slotWidth - iconWidth - gap, mSmallFont);
        var textWidth = dc.getTextWidthInPixels(text, selectedFont);
        var groupWidth = iconWidth + gap + textWidth;
        var groupLeft = center - groupWidth / 2;
        var iconX = groupLeft + iconWidth / 2;
        if (kind == 0) { drawThermometerIcon(dc, iconX, y, iconColor); }
        else if (kind == 1) { drawDropIcon(dc, iconX, y, iconColor); }
        else if (kind == 3) { drawPercentIcon(dc, iconX, y, iconColor); }
        else { drawWindIcon(dc, iconX, y, iconColor); }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(groupLeft + iconWidth + gap, y, selectedFont, text, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawNextSunEvent(dc, weather, lowPower, color) {
        var solar = nextSunEvent(weather);
        var iconColor = lowPower ? color : 0xD6B641;
        drawPackedMetricWithFont(dc, 227, 92, 256, solar[:sunrise] ? 2 : 3, solar[:time], color, iconColor, mValueFont);
    }

    function drawWeatherCenter(dc, cx, cy, weather, lowPower, textColor, accent) {
        var temperature = value(weather == null ? null : weather.temperature, "--") + "°";
        var iconWidth = 64;
        var gap = 9;
        var textFont = fitTextFont(dc, temperature, 300 - iconWidth - gap, mTempFont);
        var textWidth = dc.getTextWidthInPixels(temperature, textFont);
        var groupWidth = iconWidth + gap + textWidth;
        var groupLeft = cx - groupWidth / 2;
        var iconX = groupLeft + iconWidth / 2;
        if (lowPower) { drawAodWeatherIcon(dc, iconX, cy - 5, textColor, weather); }
        else { drawWeatherIcon(dc, iconX, cy - 5, weather); }
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(groupLeft + iconWidth + gap, cy - 10, textFont, temperature, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawCenteredFitText(dc, x, y, text, preferredFont, maxWidth, color) {
        var selectedFont = fitTextFont(dc, text, maxWidth, preferredFont);
        drawText(dc, x, y, text, selectedFont, color);
    }

    function drawDateBox(dc, lowPower, ink, accent) {
        // The original analog reference places a small framed date at 3 o'clock.
        var left = 254;
        var top = 223;
        var width = 170;
        var height = 34;
        var frame = lowPower ? 0x55595D : 0x858A8F;
        dc.setColor(frame, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(left, top, width, height);
        var dateInfo = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var weekday = dateInfo.day_of_week.substring(0, 2).toUpper();
        var dateText = weekday + " " + dateInfo.day.format("%02d") + " " + dateInfo.month.toUpper();
        drawCenteredFitText(dc, left + width / 2, top + height / 2, dateText, mValueFont, width - 6, lowPower ? ink : accent);
    }

    function fitTextFont(dc, text, maxWidth, preferredFont) {
        if (preferredFont != null && dc.getTextWidthInPixels(text, preferredFont) <= maxWidth) { return preferredFont; }
        for (var i = 0; i < mMetricFonts.size(); i += 1) {
            var candidate = mMetricFonts[i];
            if (dc.getTextWidthInPixels(text, candidate) <= maxWidth) { return candidate; }
        }
        return mMetricFonts[mMetricFonts.size() - 1];
    }

    function drawDatePanel(dc, clock) {
        drawPanel(dc, 70, 67, 94, 48, 0x252B31);
        drawDateContents(dc, 0xF2F5F7);
    }

    function drawLowPowerFace(dc, cx, cy, clock, weather) {
        // Keep the same information in AMOLED always-on mode while avoiding
        // filled panels so the update remains within Garmin's pixel budget.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var dim = 0x777D82;
        drawDateContents(dc, dim);
        var solar = nextSunEvent(weather);
        drawMetricValue(dc, 70, 121, 94, 49, solar[:sunrise] ? 2 : 3, solar[:time], dim, dim);
        drawWeatherContents(dc, weather, true, dim);
        drawTimeContents(dc, cx, cy, clock, dim);

        var monitor = ActivityMonitor.getInfo();
        var heartRate = latestHeartRate();
        var altitude = latestElevation();
        var stats = System.getSystemStats();
        var altitudeText = altitude == null ? "--" : altitude.format("%d") + "m";
        var activeMinutes = monitor.activeMinutesWeek;
        var weeklyMinutes = activeMinutes == null ? "--m" : activeMinutes.total.format("%d") + "m";
        drawMetricValue(dc, 62, 271, 94, 50, 0, grouped(monitor.steps), dim, dim);
        drawMetricValue(dc, 180, 271, 94, 50, 1, value(heartRate, "--") + "bpm", dim, dim);
        drawMetricValue(dc, 298, 271, 94, 50, 5, altitudeText, dim, dim);
        drawMetricValue(dc, 62, 327, 94, 50, 4, grouped(activeCalories(monitor.calories)), dim, dim);
        drawMetricValue(dc, 180, 327, 94, 50, 7, weeklyMinutes, dim, dim);
        drawMetricValue(dc, 298, 327, 94, 50, 6, stats.battery.format("%d") + "%", dim, dim);
    }

    function currentDateLine() {
        var dateInfo = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        return dateInfo.day.format("%02d") + " " + dateInfo.day_of_week + " " + dateInfo.month;
    }

    function drawAodWeatherIcon(dc, x, y, color, weather) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var condition = weather == null ? Weather.CONDITION_UNKNOWN : weather.condition;
        var night = isNightAt(weather);
        var sunny = condition == Weather.CONDITION_CLEAR || condition == Weather.CONDITION_MOSTLY_CLEAR || condition == Weather.CONDITION_FAIR;
        var storm = condition == Weather.CONDITION_THUNDERSTORMS || condition == Weather.CONDITION_SCATTERED_THUNDERSTORMS || condition == Weather.CONDITION_CHANCE_OF_THUNDERSTORMS;
        if (sunny && !night) {
            dc.drawCircle(x, y, 9);
            dc.drawLine(x, y - 15, x, y - 11);
            dc.drawLine(x, y + 11, x, y + 15);
            dc.drawLine(x - 15, y, x - 11, y);
            dc.drawLine(x + 11, y, x + 15, y);
        } else {
            if (night) {
                dc.drawCircle(x + 7, y - 9, 7);
                dc.drawLine(x + 7, y - 18, x + 7, y - 15);
                dc.drawLine(x + 14, y - 9, x + 17, y - 9);
            }
            if (!sunny || !night) {
            dc.drawCircle(x - 7, y, 7);
            dc.drawCircle(x, y - 4, 9);
            dc.drawCircle(x + 8, y + 1, 6);
            dc.drawLine(x - 13, y + 5, x + 14, y + 5);
            if (isRainCondition(condition) || storm) {
                dc.drawLine(x - 7, y + 9, x - 9, y + 14);
                dc.drawLine(x + 2, y + 9, x, y + 14);
            } else if (isSnowCondition(condition)) {
                drawSnowflake(dc, x - 6, y + 14);
                drawSnowflake(dc, x + 6, y + 14);
            } else if (condition == Weather.CONDITION_FOG || condition == Weather.CONDITION_MIST || condition == Weather.CONDITION_HAZE || condition == Weather.CONDITION_HAZY) {
                dc.drawLine(x - 12, y + 11, x + 12, y + 11);
                dc.drawLine(x - 9, y + 16, x + 9, y + 16);
            }
            if (storm) {
                dc.drawLine(x + 5, y + 7, x, y + 14);
                dc.drawLine(x, y + 14, x + 4, y + 14);
                dc.drawLine(x + 4, y + 14, x + 1, y + 19);
            }
            }
        }
    }

    function weatherLocation(weather) {
        var place = weather == null ? null : weather.observationLocationName;
        var observationPosition = weather == null ? null : weather.observationLocationPosition;
        if (place != null && place.length() > 0 && !positionsDisagree(observationPosition, mPositionCache)) { return place; }
        var location = weather == null ? null : weather.observationLocationPosition;
        if (mPositionCache != null) {
            location = mPositionCache;
        }
        if (location != null) {
            var degrees = location.toDegrees();
            if (degrees != null && degrees.size() >= 2) {
                var city = nearestRomanianCity(degrees[0], degrees[1]);
                if (city != null) { return city; }
                // CI has no reverse-geocoding endpoint; coordinates are the truthful fallback.
                return degrees[0].format("%.2f") + "," + degrees[1].format("%.2f");
            }
        }
        return "NO FIX";
    }

    function positionsDisagree(first, second) {
        if (first == null || second == null) { return false; }
        var a = first.toDegrees();
        var b = second.toDegrees();
        if (a == null || b == null || a.size() < 2 || b.size() < 2) { return false; }
        var latDiff = a[0] - b[0];
        var lonDiff = a[1] - b[1];
        if (latDiff < 0) { latDiff = -latDiff; }
        if (lonDiff < 0) { lonDiff = -lonDiff; }
        return latDiff > 0.35 || lonDiff > 0.45;
    }

    function nearestRomanianCity(lat, lon) {
        var cities = [
            ["București", 44.4268, 26.1025], ["Iași", 47.1585, 27.6014],
            ["Cluj-Napoca", 46.7712, 23.6236], ["Timișoara", 45.7489, 21.2087],
            ["Constanța", 44.1598, 28.6348], ["Brașov", 45.6427, 25.5887],
            ["Craiova", 44.3302, 23.7949], ["Galați", 45.4353, 28.0080],
            ["Oradea", 47.0465, 21.9189], ["Ploiești", 44.9367, 26.0130],
            ["Sibiu", 45.7983, 24.1256], ["Arad", 46.1866, 21.3123],
            ["Pitești", 44.8565, 24.8692], ["Bacău", 46.5670, 26.9146],
            ["Târgu Mureș", 46.5386, 24.5570], ["Baia Mare", 47.6573, 23.5681]
        ];
        var closest = null;
        var best = 999.0;
        for (var i = 0; i < cities.size(); i += 1) {
            var dlat = lat - cities[i][1];
            var dlon = (lon - cities[i][2]) * 0.70;
            var score = dlat * dlat + dlon * dlon;
            if (score < best) { best = score; closest = cities[i][0]; }
        }
        return best < 0.035 ? closest : null;
    }

    function settingNumber(key, fallback) {
        var value = Application.Properties.getValue(key);
        return value == null ? fallback : value;
    }

    function settingBoolean(key, fallback) {
        var value = Application.Properties.getValue(key);
        return value == null ? fallback : value;
    }

    function drawWeatherPanel(dc, weather) {
        drawPanel(dc, 171, 67, 204, 108, weatherBackground(weather));
        drawWeatherContents(dc, weather, false, Graphics.COLOR_WHITE);
    }

    function drawDateContents(dc, color) {
        drawCalendarIcon(dc, 91, 78, color);
        drawText(dc, 117, 103, currentDateLine(), mDateFont, color);
    }

    function drawWeatherContents(dc, weather, lowPower, textColor) {
        var place = weatherLocation(weather);
        if (place.length() > 13) { place = place.substring(0, 13); }

        if (lowPower) { drawAodWeatherIcon(dc, 197, 89, textColor, weather); }
        else { drawWeatherIcon(dc, 197, 89, weather); }
        drawText(dc, 275, 88, value(weather == null ? null : weather.temperature, "--") + "°C", mTempFont, textColor);
        drawLocationIcon(dc, 190, 121, textColor);
        drawText(dc, 286, 122, place, mSmallFont, textColor);

        var low = weather == null ? null : weather.lowTemperature;
        var high = weather == null ? null : weather.highTemperature;
        var days = Weather.getDailyForecast();
        if (days != null && days.size() > 0 && days[0] != null) {
            if (low == null) { low = days[0].lowTemperature; }
            if (high == null) { high = days[0].highTemperature; }
        }
        var detailColor = lowPower ? textColor : 0xD5DCE1;
        drawThermometerIcon(dc, 177, 143, detailColor);
        drawText(dc, 226, 143, value(low, "--") + "°/" + value(high, "--") + "°", mSmallFont, detailColor);

        var wind = weather == null ? null : weather.windSpeed;
        var windText = wind == null ? "--" : (wind * 3.6).format("%d");
        var windColor = lowPower ? textColor : 0x72C8EF;
        drawWindIcon(dc, 277, 143, windColor);
        drawText(dc, 332, 143, windText + "km/h", mSmallFont, detailColor);

        var rain = weather == null ? null : weather.precipitationChance;
        var rainAt = nextRainTime(weather);
        drawDropIcon(dc, 177, 162, windColor);
        drawText(dc, 226, 162, value(rain, "--") + "%", mSmallFont, detailColor);
        drawDropIcon(dc, 277, 162, windColor);
        drawText(dc, 332, 162, rainAt, mSmallFont, detailColor);
    }

    function drawTimePanel(dc, cx, cy, clock) {
        drawPanel(dc, 35, 176, 384, 89, 0x070A0D);
        drawTimeContents(dc, cx, cy, clock, Graphics.COLOR_WHITE);
    }

    function drawTimeContents(dc, cx, cy, clock, color) {
        var text = clock.hour.format("%02d") + ":" + clock.min.format("%02d");
        drawText(dc, cx, cy + 1, text, mTimeFont, color);
    }

    function drawMetricCell(dc, x, y, width, height, icon, text, accent) {
        drawPanel(dc, x, y, width, height, 0x171C22);
        drawMetricValue(dc, x, y, width, height, icon, text, Graphics.COLOR_WHITE, accent);
    }

    function drawMetricValue(dc, x, y, width, height, icon, text, color, accent) {
        var iconX = x + 21;
        var iconY = y + height / 2;
        var iconColor = accent == null ? color : accent;
        drawMetricIcon(dc, icon, iconX, iconY, iconColor);
        var metricFont = width < 100 ? mCompactFont : mValueFont;
        drawText(dc, x + width * 0.70, iconY, text, metricFont, color);
    }

    function drawPackedMetric(dc, center, y, slotWidth, icon, text, color, accent) {
        drawPackedMetricWithFont(dc, center, y, slotWidth, icon, text, color, accent, mValueFont);
    }

    function drawPackedMetricWithFont(dc, center, y, slotWidth, icon, text, color, accent, preferredFont) {
        // Measure each changing value and fit it after the icon inside its own column.
        var iconWidth = 24;
        var gap = 5;
        var availableTextWidth = slotWidth - iconWidth - gap;
        var selectedFont = fitTextFont(dc, text, availableTextWidth, preferredFont);
        var textWidth = dc.getTextWidthInPixels(text, selectedFont);
        var groupWidth = iconWidth + gap + textWidth;
        var groupLeft = center - groupWidth / 2;
        var iconColor = accent == null ? color : accent;
        drawMetricIcon(dc, icon, groupLeft + iconWidth / 2, y, iconColor);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(groupLeft + iconWidth + gap, y, selectedFont, text, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawMetricIcon(dc, icon, iconX, iconY, iconColor) {
        if (icon == 0) { drawStepsIcon(dc, iconX, iconY, iconColor); }
        else if (icon == 1) { drawHeartIcon(dc, iconX, iconY, iconColor); }
        else if (icon == 2) { drawSunEventIcon(dc, iconX, iconY, true, iconColor); }
        else if (icon == 3) { drawSunEventIcon(dc, iconX, iconY, false, iconColor); }
        else if (icon == 4) { drawFlameIcon(dc, iconX, iconY, iconColor); }
        else if (icon == 5) { drawMountainIcon(dc, iconX, iconY, iconColor); }
        else if (icon == 6) { drawBatteryIcon(dc, iconX, iconY, iconColor); }
        else if (icon == 7) { drawIntensityIcon(dc, iconX, iconY, iconColor); }
    }

    function drawPanel(dc, x, y, width, height, fill) {
        dc.setColor(fill, fill);
        dc.fillRoundedRectangle(x, y, width, height, 10);
        dc.setColor(0x3E4952, 0x3E4952);
        dc.drawRoundedRectangle(x, y, width, height, 10);
    }

    function drawText(dc, x, y, text, font, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var selectedFont = font == null ? Graphics.FONT_SMALL : font;
        dc.drawText(x, y, selectedFont, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawThickLine(dc, x1, y1, x2, y2, thickness) {
        var dx = x2 - x1;
        var dy = y2 - y1;
        var length = Math.sqrt(dx * dx + dy * dy);
        if (length <= 0) { return; }
        var ox = -dy / length;
        var oy = dx / length;
        for (var i = -thickness; i <= thickness; i += 1) {
            dc.drawLine(x1 + ox * i, y1 + oy * i, x2 + ox * i, y2 + oy * i);
        }
    }

    function drawCalendarIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x - 10, y - 9, 20, 19, 4);
        dc.drawLine(x - 9, y - 3, x + 9, y - 3);
        dc.drawLine(x - 4, y - 12, x - 4, y - 6);
        dc.drawLine(x + 4, y - 12, x + 4, y - 6);
    }

    function drawLocationIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y - 2, 7);
        dc.drawLine(x - 5, y + 2, x, y + 10);
        dc.drawLine(x + 5, y + 2, x, y + 10);
        dc.setColor(color, color);
        dc.fillCircle(x, y - 2, 3);
    }

    function drawThermometerIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x, y - 9, x, y + 4);
        dc.drawCircle(x, y + 7, 5);
        dc.setColor(color, color);
        dc.fillCircle(x, y + 7, 3);
    }

    function drawWindIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x - 9, y - 5, x + 7, y - 5);
        dc.drawLine(x - 11, y, x + 5, y);
        dc.drawLine(x - 6, y + 5, x + 9, y + 5);
        dc.drawCircle(x + 9, y - 5, 2);
    }

    function drawDropIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x, y - 10, x - 6, y + 2);
        dc.drawLine(x, y - 10, x + 6, y + 2);
        dc.drawArc(x, y + 2, 6, Graphics.ARC_CLOCKWISE, 0, 180);
    }

    function drawPercentIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x - 5, y - 5, 2);
        dc.drawCircle(x + 5, y + 5, 2);
        dc.drawLine(x - 7, y + 8, x + 7, y - 8);
    }

    function drawStepsIcon(dc, x, y, color) {
        dc.setColor(color, color);
        dc.fillCircle(x - 5, y - 5, 4);
        dc.fillCircle(x + 5, y + 4, 4);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x - 9, y, x - 1, y + 5);
        dc.drawLine(x + 1, y + 9, x + 10, y + 1);
    }

    function drawHeartIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(x - 5, y - 4, 6, Graphics.ARC_CLOCKWISE, 0, 180);
        dc.drawArc(x + 5, y - 4, 6, Graphics.ARC_COUNTER_CLOCKWISE, 0, 180);
        dc.drawLine(x - 10, y - 2, x, y + 10);
        dc.drawLine(x + 10, y - 2, x, y + 10);
    }

    function drawSunEventIcon(dc, x, y, sunrise, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(x, y + 5, 9, sunrise ? Graphics.ARC_CLOCKWISE : Graphics.ARC_COUNTER_CLOCKWISE, 0, 180);
        dc.drawLine(x - 12, y + 6, x + 12, y + 6);
        if (sunrise) {
            dc.drawLine(x, y - 11, x, y - 3);
            dc.drawLine(x - 9, y - 7, x - 5, y - 3);
            dc.drawLine(x + 9, y - 7, x + 5, y - 3);
        } else {
            dc.drawLine(x, y - 3, x, y - 11);
            dc.drawLine(x - 9, y - 3, x - 5, y - 7);
            dc.drawLine(x + 9, y - 3, x + 5, y - 7);
        }
    }

    function drawFlameIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x, y - 12, x - 9, y + 1);
        dc.drawLine(x - 9, y + 1, x - 8, y + 9);
        dc.drawLine(x - 8, y + 9, x, y + 12);
        dc.drawLine(x, y + 12, x + 9, y + 5);
        dc.drawLine(x + 9, y + 5, x + 5, y - 5);
        dc.drawLine(x + 5, y - 5, x, y - 12);
        dc.drawLine(x, y - 2, x - 4, y + 6);
        dc.drawLine(x - 4, y + 6, x + 3, y + 8);
    }

    function drawMountainIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x - 12, y + 9, x - 3, y - 8);
        dc.drawLine(x - 3, y - 8, x + 4, y + 2);
        dc.drawLine(x + 4, y + 2, x + 8, y - 7);
        dc.drawLine(x + 8, y - 7, x + 13, y + 9);
        dc.drawLine(x - 12, y + 9, x + 13, y + 9);
    }

    function drawBatteryIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x - 12, y - 8, 21, 16);
        dc.drawRectangle(x + 9, y - 4, 4, 8);
        dc.setColor(color, color);
        dc.fillRectangle(x - 9, y - 4, 14, 8);
    }

    function drawIntensityIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y, 10);
        dc.drawLine(x, y - 6, x, y);
        dc.drawLine(x, y, x + 5, y + 3);
    }

    function drawWeatherIcon(dc, x, y, weather) {
        var condition = weather == null ? Weather.CONDITION_UNKNOWN : weather.condition;
        var night = isNightAt(weather);
        var sunny = condition == Weather.CONDITION_CLEAR || condition == Weather.CONDITION_MOSTLY_CLEAR || condition == Weather.CONDITION_FAIR;
        var partly = condition == Weather.CONDITION_PARTLY_CLOUDY || condition == Weather.CONDITION_PARTLY_CLEAR || condition == Weather.CONDITION_THIN_CLOUDS;
        var rainy = isRainCondition(condition);
        var snowy = isSnowCondition(condition);
        var storm = condition == Weather.CONDITION_THUNDERSTORMS || condition == Weather.CONDITION_SCATTERED_THUNDERSTORMS || condition == Weather.CONDITION_CHANCE_OF_THUNDERSTORMS;
        var fog = condition == Weather.CONDITION_FOG || condition == Weather.CONDITION_MIST || condition == Weather.CONDITION_HAZE || condition == Weather.CONDITION_HAZY;
        var windy = condition == Weather.CONDITION_WINDY || condition == Weather.CONDITION_SQUALL;
        if ((sunny || partly) && !night) {
            dc.setColor(0xFFBD59, 0xFFBD59);
            dc.fillCircle(x + 1, y - 8, 11);
            dc.setColor(0xFFBD59, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(x + 1, y - 25, x + 1, y - 21);
            dc.drawLine(x - 15, y - 8, x - 11, y - 8);
            dc.drawLine(x + 13, y - 8, x + 17, y - 8);
        }
        if (!sunny) {
            if (night) {
                dc.setColor(0xD6DDF5, 0xD6DDF5);
                dc.fillCircle(x + 16, y - 17, 7);
                dc.setColor(0x07090B, 0x07090B);
                dc.fillCircle(x + 20, y - 20, 6);
            }
            dc.setColor(0xDDE8EE, 0xDDE8EE);
            dc.fillCircle(x - 12, y + 2, 8);
            dc.fillCircle(x, y - 3, 12);
            dc.fillCircle(x + 12, y + 3, 8);
            dc.fillRectangle(x - 12, y + 2, 24, 9);
        }
        if (sunny && night) {
            dc.setColor(0xD6DDF5, 0xD6DDF5);
            dc.fillCircle(x, y - 8, 11);
            dc.setColor(0x07090B, 0x07090B);
            dc.fillCircle(x + 5, y - 12, 9);
        }
        if (rainy || storm) {
            dc.setColor(0x72C8EF, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(x - 8, y + 14, x - 10, y + 20);
            dc.drawLine(x, y + 14, x - 2, y + 20);
            dc.drawLine(x + 8, y + 14, x + 6, y + 20);
        } else if (snowy) {
            dc.setColor(0xBFE8FF, Graphics.COLOR_TRANSPARENT);
            drawSnowflake(dc, x - 7, y + 17);
            drawSnowflake(dc, x + 7, y + 17);
        }
        if (storm) {
            dc.setColor(0xFFBD59, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(x + 3, y + 8, x - 2, y + 16);
            dc.drawLine(x - 2, y + 16, x + 3, y + 16);
            dc.drawLine(x + 3, y + 16, x - 1, y + 22);
        } else if (!snowy && fog) {
            dc.setColor(0xAFBBC5, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(x - 13, y + 14, x + 13, y + 14);
            dc.drawLine(x - 10, y + 19, x + 10, y + 19);
        } else if (!snowy && !fog && windy) {
            dc.setColor(0xA8DDEB, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(x - 15, y + 14, x + 12, y + 14);
            dc.drawLine(x - 10, y + 19, x + 8, y + 19);
        }
    }

    function isNightAt(weather) {
        var location = weather == null ? null : weather.observationLocationPosition;
        if (location == null) {
            location = mPositionCache;
        }
        if (location != null) {
            var now = Time.now();
            var sunrise = Weather.getSunrise(location, now);
            var sunset = Weather.getSunset(location, now);
            if (sunrise != null && sunset != null) {
                return now.lessThan(sunrise) || !now.lessThan(sunset);
            }
        }
        var hour = System.getClockTime().hour;
        return hour >= 19 || hour < 6;
    }

    function drawSnowflake(dc, x, y) {
        dc.drawLine(x - 3, y, x + 3, y);
        dc.drawLine(x, y - 3, x, y + 3);
        dc.drawLine(x - 2, y - 2, x + 2, y + 2);
        dc.drawLine(x - 2, y + 2, x + 2, y - 2);
    }

    function isRainCondition(condition) {
        return condition == Weather.CONDITION_RAIN || condition == Weather.CONDITION_LIGHT_RAIN || condition == Weather.CONDITION_HEAVY_RAIN || condition == Weather.CONDITION_DRIZZLE || condition == Weather.CONDITION_SCATTERED_SHOWERS || condition == Weather.CONDITION_LIGHT_SHOWERS || condition == Weather.CONDITION_SHOWERS || condition == Weather.CONDITION_HEAVY_SHOWERS || condition == Weather.CONDITION_CHANCE_OF_SHOWERS || condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN || condition == Weather.CONDITION_FREEZING_RAIN || condition == Weather.CONDITION_HAIL || condition == Weather.CONDITION_TORNADO || condition == Weather.CONDITION_HURRICANE || condition == Weather.CONDITION_TROPICAL_STORM;
    }

    function isSnowCondition(condition) {
        return condition == Weather.CONDITION_SNOW || condition == Weather.CONDITION_LIGHT_SNOW || condition == Weather.CONDITION_HEAVY_SNOW || condition == Weather.CONDITION_FLURRIES || condition == Weather.CONDITION_CHANCE_OF_SNOW || condition == Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW || condition == Weather.CONDITION_WINTRY_MIX || condition == Weather.CONDITION_RAIN_SNOW || condition == Weather.CONDITION_LIGHT_RAIN_SNOW || condition == Weather.CONDITION_HEAVY_RAIN_SNOW || condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW || condition == Weather.CONDITION_CHANCE_OF_RAIN_SNOW || condition == Weather.CONDITION_ICE_SNOW || condition == Weather.CONDITION_SLEET;
    }

    function value(input, fallback) {
        return input == null ? fallback : input.format("%d");
    }

    function grouped(input) {
        if (input == null) { return "--"; }
        var raw = input.format("%d");
        var out = "";
        var count = 0;
        for (var i = raw.length() - 1; i >= 0; i -= 1) {
            out = raw.substring(i, i + 1) + out;
            count += 1;
            if (count == 3 && i > 0) { out = "." + out; count = 0; }
        }
        return out;
    }

    function activeCalories(totalCalories) {
        // Garmin's ActivityMonitor exposes total daily calories, not active calories.
        // Estimate resting calories from the profile, prorated from midnight to now.
        if (totalCalories == null) { return null; }
        var profile = UserProfile.getProfile();
        if (profile == null || profile.birthYear == null || profile.height == null || profile.weight == null || profile.gender == null) {
            return null;
        }

        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var age = now.year - profile.birthYear;
        if (age < 1 || profile.height <= 0 || profile.weight <= 0) { return null; }

        var weightKg = profile.weight / 1000.0;
        var restingCaloriesPerDay = 0.0;
        if (profile.gender == UserProfile.GENDER_MALE) {
            restingCaloriesPerDay = 5.2 - 6.116 * age + 7.628 * profile.height + 12.2 * weightKg;
        } else if (profile.gender == UserProfile.GENDER_FEMALE) {
            restingCaloriesPerDay = -197.6 - 6.116 * age + 7.628 * profile.height + 12.2 * weightKg;
        } else {
            return null;
        }

        var minutesToday = now.hour * 60 + now.min;
        var restingCaloriesSoFar = Math.round(minutesToday * restingCaloriesPerDay / 1440.0).toNumber();
        var active = (totalCalories - restingCaloriesSoFar).toNumber();
        return active < 0 ? 0 : active;
    }

    function weatherBackground(weather) {
        if (weather == null || weather.condition == null) { return 0x18232C; }
        var condition = weather.condition;
        if (condition == Weather.CONDITION_CLEAR || condition == Weather.CONDITION_MOSTLY_CLEAR || condition == Weather.CONDITION_FAIR) { return 0x392B16; }
        if (condition == Weather.CONDITION_PARTLY_CLOUDY || condition == Weather.CONDITION_PARTLY_CLEAR || condition == Weather.CONDITION_THIN_CLOUDS) { return 0x20313A; }
        if (isRainCondition(condition)) { return 0x10283A; }
        if (isSnowCondition(condition)) { return 0x273442; }
        if (condition == Weather.CONDITION_THUNDERSTORMS || condition == Weather.CONDITION_SCATTERED_THUNDERSTORMS || condition == Weather.CONDITION_CHANCE_OF_THUNDERSTORMS) { return 0x241B36; }
        if (condition == Weather.CONDITION_FOG || condition == Weather.CONDITION_MIST || condition == Weather.CONDITION_HAZE || condition == Weather.CONDITION_HAZY || condition == Weather.CONDITION_SMOKE) { return 0x303439; }
        if (condition == Weather.CONDITION_WINDY || condition == Weather.CONDITION_SQUALL) { return 0x1D3033; }
        if (condition == Weather.CONDITION_CLOUDY || condition == Weather.CONDITION_MOSTLY_CLOUDY) { return 0x2C3238; }
        return 0x18232C;
    }

    function nextSunEvent(weather) {
        var missing = {:sunrise => true, :time => "--:--"};
        if (weather == null || weather.observationLocationPosition == null) { return missing; }
        var location = weather.observationLocationPosition;
        var now = Time.now();
        var sunrise = Weather.getSunrise(location, now);
        var sunset = Weather.getSunset(location, now);
        if (sunrise != null && sunrise.greaterThan(now)) {
            return {:sunrise => true, :time => formatSunTime(location, sunrise)};
        }
        if (sunset != null && sunset.greaterThan(now)) {
            return {:sunrise => false, :time => formatSunTime(location, sunset)};
        }
        var tomorrow = now.add(new Time.Duration(Gregorian.SECONDS_PER_DAY));
        sunrise = Weather.getSunrise(location, tomorrow);
        if (sunrise != null) {
            return {:sunrise => true, :time => formatSunTime(location, sunrise)};
        }
        return missing;
    }

    function nextRainTime(weather) {
        var location = weather == null ? null : weather.observationLocationPosition;
        if (location == null) { return "--:--"; }
        var hours = Weather.getHourlyForecast();
        if (hours == null) { return "--:--"; }
        var now = Time.now();
        for (var i = 0; i < hours.size(); i += 1) {
            var hour = hours[i];
            if (hour == null || hour.forecastTime == null || !hour.forecastTime.greaterThan(now)) { continue; }
            var wetCondition = hour.condition == Weather.CONDITION_RAIN || hour.condition == Weather.CONDITION_LIGHT_RAIN || hour.condition == Weather.CONDITION_HEAVY_RAIN || hour.condition == Weather.CONDITION_THUNDERSTORMS;
            var likelyRain = hour.precipitationChance != null && hour.precipitationChance >= 50;
            if (wetCondition || likelyRain) {
                var local = Gregorian.localMoment(location, hour.forecastTime);
                if (local == null) { return "--:--"; }
                var info = Gregorian.info(local, Time.FORMAT_SHORT);
                return info.hour.format("%02d") + ":" + info.min.format("%02d");
            }
        }
        return "--:--";
    }

    function formatSunTime(location, moment) {
        if (moment == null) { return "--:--"; }
        var local = Gregorian.localMoment(location, moment);
        if (local == null) { return "--:--"; }
        var info = Gregorian.info(local, Time.FORMAT_SHORT);
        return info.hour.format("%02d") + ":" + info.min.format("%02d");
    }

    function latestHeartRate() {
        var history = ActivityMonitor.getHeartRateHistory(3, true);
        if (history == null) { return null; }
        for (var i = 0; i < 3; i += 1) {
            var sample = history.next();
            if (sample == null) { return null; }
            if (sample.heartRate != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                return sample.heartRate;
            }
        }
        return null;
    }

    function latestElevation() {
        var history = SensorHistory.getElevationHistory({:period => 2, :order => SensorHistory.ORDER_NEWEST_FIRST});
        var sample = history == null ? null : history.next();
        return sample == null ? null : sample.data;
    }
}

// Provides the 454px design coordinate space on smaller round displays.
class ScaledWatchFaceDc {
    var mTarget = null;
    var mScale = 1.0;
    var mSourceFonts = null;
    var mTargetFonts = null;

    function initialize(target, scale, sourceFonts, targetFonts) {
        mTarget = target;
        mScale = scale;
        mSourceFonts = sourceFonts;
        mTargetFonts = targetFonts;
    }

    function getWidth() { return 454; }
    function getHeight() { return 454; }
    function setColor(foreground, background) { mTarget.setColor(foreground, background); }
    function clear() { mTarget.clear(); }
    function drawCircle(x, y, radius) { mTarget.drawCircle(x * mScale, y * mScale, radius * mScale); }
    function fillCircle(x, y, radius) { mTarget.fillCircle(x * mScale, y * mScale, radius * mScale); }
    function drawLine(x1, y1, x2, y2) { mTarget.drawLine(x1 * mScale, y1 * mScale, x2 * mScale, y2 * mScale); }
    function drawArc(x, y, radius, arcType, startAngle, endAngle) {
        mTarget.drawArc(x * mScale, y * mScale, radius * mScale, arcType, startAngle, endAngle);
    }
    function drawRectangle(x, y, width, height) { mTarget.drawRectangle(x * mScale, y * mScale, width * mScale, height * mScale); }
    function fillRectangle(x, y, width, height) { mTarget.fillRectangle(x * mScale, y * mScale, width * mScale, height * mScale); }
    function drawRoundedRectangle(x, y, width, height, radius) {
        mTarget.drawRoundedRectangle(x * mScale, y * mScale, width * mScale, height * mScale, radius * mScale);
    }
    function fillRoundedRectangle(x, y, width, height, radius) {
        mTarget.fillRoundedRectangle(x * mScale, y * mScale, width * mScale, height * mScale, radius * mScale);
    }
    function getTextWidthInPixels(text, font) {
        return mTarget.getTextWidthInPixels(text, scaledFont(font)) / mScale;
    }
    function drawText(x, y, font, text, justification) {
        mTarget.drawText(x * mScale, y * mScale, scaledFont(font), text, justification);
    }

    function scaledFont(font) {
        for (var i = 0; i < mSourceFonts.size(); i += 1) {
            if (font == mSourceFonts[i]) { return mTargetFonts[i]; }
        }
        return font;
    }
}

class VreDoComplicationBounds extends WatchUi.Drawable {
    function initialize(options) {
        Drawable.initialize(options);
    }

    function draw(dc) {
        if (!isVisible) { return; }
        var x = locX.toNumber();
        var y = locY.toNumber();
        var w = width.toNumber();
        var h = height.toNumber();
        dc.setColor(0xFFD34E, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x, y, w, h, 5);
        if (w > 4 && h > 4) {
            dc.drawRoundedRectangle(x + 2, y + 2, w - 4, h - 4, 3);
        }
    }
}

