using Toybox.ActivityMonitor;
using Toybox.Graphics;
using Toybox.SensorHistory;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;
using Toybox.Weather;

class VreDoWatchFaceView extends WatchUi.WatchFace {
    var mLowPower = false;
    var mValueFont = null;
    var mSmallFont = null;
    var mTempFont = null;
    var mTimeFont = null;

    function initialize() {
        WatchFace.initialize();
        var faces = ["RobotoCondensedRegular", "RobotoRegular"];
        mValueFont = Graphics.getVectorFont({:face => faces, :size => 17});
        mSmallFont = Graphics.getVectorFont({:face => faces, :size => 14});
        mTempFont = Graphics.getVectorFont({:face => faces, :size => 32});
        mTimeFont = Graphics.getVectorFont({:face => faces, :size => 76});
    }

    function onEnterSleep() { mLowPower = true; }
    function onExitSleep() { mLowPower = false; }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;
        var clock = System.getClockTime();
        var weather = Weather.getCurrentConditions();

        if (mLowPower) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();
            drawText(dc, cx, cy, clock.hour.format("%02d") + ":" + clock.min.format("%02d"), Graphics.FONT_NUMBER_HOT, 0x777F86);
            return;
        }

        var weatherBg = weatherBackground(weather);
        dc.setColor(weatherBg, weatherBg);
        dc.clear();
        dc.setColor(0x11161C, 0x11161C);
        dc.fillRectangle(cx, 0, w - cx, h);
        dc.setColor(0x3A454E, 0x3A454E);
        dc.drawCircle(cx, cy, (w / 2) - 8);

        drawDatePanel(dc, clock);
        drawWeatherPanel(dc, weather);
        drawTimePanel(dc, cx, cy, clock);

        var monitor = ActivityMonitor.getInfo();
        var heartRate = latestHeartRate();
        var altitude = latestElevation();
        var stats = System.getSystemStats();
        var solar = nextSunEvent(weather);

        // Three icon/value tiles on the first row.
        drawMetricCell(dc, 31, 271, 123, 53, "steps", grouped(monitor.steps), 0xFF9F43);
        drawMetricCell(dc, 165, 271, 123, 53, "heart", value(heartRate, "--") + "bpm", 0xFF6E73);
        drawMetricCell(dc, 299, 271, 123, 53, solar[:sunrise] ? "sunrise" : "sunset", solar[:time], 0xFFBD59);

        // The lower row stays inside the narrow part of the round display.
        var altitudeText = altitude == null ? "--" : altitude.format("%d") + "m";
        drawMetricCell(dc, 74, 331, 90, 52, "flame", grouped(monitor.calories), 0xFF9F43);
        drawMetricCell(dc, 180, 331, 94, 52, "mountain", altitudeText, 0x72C8EF);
        drawMetricCell(dc, 288, 331, 92, 52, "battery", stats.battery.format("%d") + "%", 0x70D9A0);
    }

    function drawDatePanel(dc, clock) {
        drawPanel(dc, 77, 69, 87, 74, 0x252B31);
        var accent = 0xF2F5F7;
        drawCalendarIcon(dc, 96, 105, accent);
        var dateInfo = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var date = dateInfo.day.format("%02d") + "/" + dateInfo.month.format("%02d");
        drawText(dc, 135, 105, date, mValueFont, accent);
    }

    function drawWeatherPanel(dc, weather) {
        drawPanel(dc, 171, 67, 204, 90, 0x20262D);
        var place = weather == null ? null : weather.observationLocationName;
        if (place == null) { place = "--"; }
        if (place.length() > 12) { place = place.substring(0, 12); }

        drawWeatherIcon(dc, 197, 89, weather);
        drawText(dc, 258, 88, value(weather == null ? null : weather.temperature, "--") + "°C", mTempFont, Graphics.COLOR_WHITE);
        drawLocationIcon(dc, 190, 121, 0xE4E9ED);
        drawText(dc, 247, 122, place, mSmallFont, Graphics.COLOR_WHITE);

        var low = weather == null ? null : weather.lowTemperature;
        var high = weather == null ? null : weather.highTemperature;
        var days = Weather.getDailyForecast();
        if (days != null && days.size() > 0 && days[0] != null) {
            if (low == null) { low = days[0].lowTemperature; }
            if (high == null) { high = days[0].highTemperature; }
        }
        drawThermometerIcon(dc, 181, 143, 0xAAB7C0);
        drawText(dc, 216, 143, value(low, "--") + "°/" + value(high, "--") + "°", mSmallFont, 0xD5DCE1);

        var wind = weather == null ? null : weather.windSpeed;
        var windText = wind == null ? "--" : (wind * 3.6).format("%d");
        drawWindIcon(dc, 264, 143, 0x72C8EF);
        drawText(dc, 291, 143, windText + "km/h", mSmallFont, 0xD5DCE1);

        var rain = weather == null ? null : weather.precipitationChance;
        drawDropIcon(dc, 333, 141, 0x72C8EF);
        drawText(dc, 355, 143, value(rain, "--") + "%", mSmallFont, 0xD5DCE1);
    }

    function drawTimePanel(dc, cx, cy, clock) {
        drawPanel(dc, 35, 176, 384, 89, 0x070A0D);
        var text = clock.hour.format("%02d") + ":" + clock.min.format("%02d");
        drawText(dc, cx, cy + 1, text, mTimeFont, Graphics.COLOR_WHITE);
    }

    function drawMetricCell(dc, x, y, width, height, icon, text, accent) {
        drawPanel(dc, x, y, width, height, 0x171C22);
        var iconX = x + 23;
        var iconY = y + height / 2;
        if (icon == "steps") { drawStepsIcon(dc, iconX, iconY, accent); }
        else if (icon == "heart") { drawHeartIcon(dc, iconX, iconY, accent); }
        else if (icon == "sunrise") { drawSunEventIcon(dc, iconX, iconY, true, accent); }
        else if (icon == "sunset") { drawSunEventIcon(dc, iconX, iconY, false, accent); }
        else if (icon == "flame") { drawFlameIcon(dc, iconX, iconY, accent); }
        else if (icon == "mountain") { drawMountainIcon(dc, iconX, iconY, accent); }
        else if (icon == "battery") { drawBatteryIcon(dc, iconX, iconY, accent); }
        drawText(dc, x + width * 0.67, iconY, text, mValueFont, Graphics.COLOR_WHITE);
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

    function drawCalendarIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x - 9, y - 8, 18, 17, 3);
        dc.drawLine(x - 8, y - 3, x + 8, y - 3);
        dc.drawLine(x - 4, y - 11, x - 4, y - 6);
        dc.drawLine(x + 4, y - 11, x + 4, y - 6);
    }

    function drawLocationIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(x, y - 2, 6);
        dc.drawLine(x - 4, y + 2, x, y + 9);
        dc.drawLine(x + 4, y + 2, x, y + 9);
        dc.setColor(color, color);
        dc.fillCircle(x, y - 2, 2);
    }

    function drawThermometerIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x, y - 7, x, y + 3);
        dc.drawCircle(x, y + 6, 4);
        dc.setColor(color, color);
        dc.fillCircle(x, y + 6, 2);
    }

    function drawWindIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x - 7, y - 4, x + 6, y - 4);
        dc.drawLine(x - 9, y, x + 4, y);
        dc.drawLine(x - 5, y + 4, x + 7, y + 4);
        dc.drawCircle(x + 7, y - 4, 1);
    }

    function drawDropIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x, y - 8, x - 5, y + 1);
        dc.drawLine(x, y - 8, x + 5, y + 1);
        dc.drawArc(x, y + 1, 5, Graphics.ARC_CLOCKWISE, 0, 180);
    }

    function drawStepsIcon(dc, x, y, color) {
        dc.setColor(color, color);
        dc.fillCircle(x - 4, y - 4, 3);
        dc.fillCircle(x + 4, y + 3, 3);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x - 7, y, x - 1, y + 4);
        dc.drawLine(x + 1, y + 7, x + 8, y + 1);
    }

    function drawHeartIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(x - 4, y - 3, 5, Graphics.ARC_CLOCKWISE, 0, 180);
        dc.drawArc(x + 4, y - 3, 5, Graphics.ARC_COUNTER_CLOCKWISE, 0, 180);
        dc.drawLine(x - 8, y - 2, x, y + 8);
        dc.drawLine(x + 8, y - 2, x, y + 8);
    }

    function drawSunEventIcon(dc, x, y, sunrise, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(x, y + 4, 7, sunrise ? Graphics.ARC_CLOCKWISE : Graphics.ARC_COUNTER_CLOCKWISE, 0, 180);
        dc.drawLine(x - 10, y + 5, x + 10, y + 5);
        if (sunrise) {
            dc.drawLine(x, y - 9, x, y - 3);
            dc.drawLine(x - 7, y - 5, x - 4, y - 2);
            dc.drawLine(x + 7, y - 5, x + 4, y - 2);
        } else {
            dc.drawLine(x, y - 3, x, y - 9);
            dc.drawLine(x - 7, y - 2, x - 4, y - 5);
            dc.drawLine(x + 7, y - 2, x + 4, y - 5);
        }
    }

    function drawFlameIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x, y - 10, x - 7, y + 1);
        dc.drawLine(x - 7, y + 1, x - 6, y + 7);
        dc.drawLine(x - 6, y + 7, x, y + 10);
        dc.drawLine(x, y + 10, x + 7, y + 4);
        dc.drawLine(x + 7, y + 4, x + 4, y - 4);
        dc.drawLine(x + 4, y - 4, x, y - 10);
        dc.drawLine(x, y - 2, x - 3, y + 5);
        dc.drawLine(x - 3, y + 5, x + 2, y + 7);
    }

    function drawMountainIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x - 10, y + 7, x - 2, y - 6);
        dc.drawLine(x - 2, y - 6, x + 3, y + 1);
        dc.drawLine(x + 3, y + 1, x + 7, y - 5);
        dc.drawLine(x + 7, y - 5, x + 11, y + 7);
        dc.drawLine(x - 10, y + 7, x + 11, y + 7);
    }

    function drawBatteryIcon(dc, x, y, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x - 10, y - 6, 18, 12);
        dc.drawRectangle(x + 8, y - 3, 3, 6);
        dc.setColor(color, color);
        dc.fillRectangle(x - 7, y - 3, 11, 6);
    }

    function drawWeatherIcon(dc, x, y, weather) {
        var rainy = weather != null && weather.condition == Weather.CONDITION_RAIN;
        var sunny = weather == null || weather.condition == Weather.CONDITION_CLEAR || weather.condition == Weather.CONDITION_PARTLY_CLOUDY;
        if (sunny) {
            dc.setColor(0xFFBD59, 0xFFBD59);
            dc.fillCircle(x, y - 7, 13);
        }
        dc.setColor(0xDDE8EE, 0xDDE8EE);
        dc.fillCircle(x - 12, y + 4, 9);
        dc.fillCircle(x, y - 1, 13);
        dc.fillCircle(x + 13, y + 5, 9);
        dc.fillRectangle(x - 12, y + 4, 26, 10);
        if (rainy) {
            dc.setColor(0x72C8EF, 0x72C8EF);
            dc.drawLine(x - 7, y + 16, x - 9, y + 21);
            dc.drawLine(x + 4, y + 16, x + 2, y + 21);
        }
    }

    function value(input, fallback) {
        return input == null ? fallback : input.format("%d");
    }

    function grouped(input) {
        if (input == null) { return "--"; }
        var raw = input.toString();
        var out = "";
        var count = 0;
        for (var i = raw.length() - 1; i >= 0; i -= 1) {
            out = raw.substring(i, i + 1) + out;
            count += 1;
            if (count == 3 && i > 0) { out = "." + out; count = 0; }
        }
        return out;
    }

    function weatherBackground(weather) {
        if (weather == null || weather.condition == null) { return 0x101820; }
        if (weather.condition == Weather.CONDITION_CLEAR || weather.condition == Weather.CONDITION_PARTLY_CLOUDY) { return 0x1B2527; }
        if (weather.condition == Weather.CONDITION_RAIN || weather.condition == Weather.CONDITION_LIGHT_RAIN || weather.condition == Weather.CONDITION_HEAVY_RAIN) { return 0x102437; }
        if (weather.condition == Weather.CONDITION_SNOW || weather.condition == Weather.CONDITION_LIGHT_SNOW) { return 0x202838; }
        if (weather.condition == Weather.CONDITION_THUNDERSTORMS) { return 0x201C32; }
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

    function formatSunTime(location, moment) {
        if (moment == null) { return "--:--"; }
        var local = Gregorian.localMoment(location, moment);
        if (local == null) { return "--:--"; }
        var info = Gregorian.info(local, Time.FORMAT_SHORT);
        return info.hour.format("%02d") + ":" + info.min.format("%02d");
    }

    function latestHeartRate() {
        var history = SensorHistory.getHeartRateHistory({:period => 2, :order => SensorHistory.ORDER_NEWEST_FIRST});
        var sample = history == null ? null : history.next();
        if (sample == null || sample.data == null || sample.data == ActivityMonitor.INVALID_HR_SAMPLE) { return null; }
        return sample.data;
    }

    function latestElevation() {
        var history = SensorHistory.getElevationHistory({:period => 2, :order => SensorHistory.ORDER_NEWEST_FIRST});
        var sample = history == null ? null : history.next();
        return sample == null ? null : sample.data;
    }
}

