
//@version=5
strategy("Work Of Art", overlay=true, max_labels_count=500)

showBuySell       = input(true, "Show Buy & Sell", group="BUY & SELL SIGNALS")
sensitivity       = input.float(3, "Sensitivity (1-16)", 1, 50, group="BUY & SELL SIGNALS")
percentStop       = input.float(1, "Take Profit % (0 to Disable)", 0, group="BUY & SELL SIGNALS")
maxTrades = input.int(3, "Max trades per day", group="BUY & SELL SIGNALS")
atrMultiplier = input.float(1.5, "ATR Stop Multiplier", group="BUY & SELL SIGNALS")
exitEod = input(false, "Exit EOD (End Of Day)", group="BUY & SELL SIGNALS")
offsetSignal      = input.float(5, "Signals Offset", 0, group="BUY & SELL SIGNALS")
showRibbon        = input(true, "Show Trend Ribbon", group="TREND RIBBON")
smooth1           = input.int(5, "Smoothing 1", 1, group="TREND RIBBON")
smooth2           = input.int(8, "Smoothing 2", 1, group="TREND RIBBON")
showReversal      = input(true, "Show Reversals", group="REVERSAL SIGNALS")
showPdHlc         = input(false, "Show P.D H/L/C", group="PREVIOUS DAY HIGH LOW CLOSE")
showProfitLines   = input(true, "Show Profile/Sl lines", group="BUY & SELL SIGNALS")
lineColor         = input.color(color.yellow, "Line Colors", group="PREVIOUS DAY HIGH LOW CLOSE")
lineWidth         = input.int(1, "Width Lines", group="PREVIOUS DAY HIGH LOW CLOSE")
lineStyle         = input.string("Solid", "Line Style", ["Solid", "Dashed", "Dotted"])
labelSize         = input.string("normal", "Label Text Size", ["small", "normal", "large"])
labelColor        = input.color(color.yellow, "Label Text Colors")
showEmas          = input(false, "Show EMAs", group="EMA")
srcEma1           = input(close, "Source EMA 1")
lenEma1           = input.int(7, "Length EMA 1", 1)
srcEma2           = input(close, "Source EMA 2")
lenEma2           = input.int(21, "Length EMA 2", 1)
srcEma3           = input(close, "Source EMA 3")
lenEma3           = input.int(144, "Length EMA 3", 1)
showSwing         = input(false, "Show Swing Points", group="SWING POINTS")
prdSwing          = input.int(10, "Swing Point Period", 2, group="SWING POINTS")
colorPos          = input(color.new(color.green, 50), "Positive Swing Color")
colorNeg          = input(color.new(color.red, 50), "Negative Swing Color")
showDashboard     = input(true, "Show Dashboard", group="TREND DASHBOARD")
locationDashboard = input.string("Middle Right", "Table Location", ["Top Right", "Middle Right", "Bottom Right", "Top Center", "Middle Center", "Bottom Center", "Top Left", "Middle Left", "Bottom Left"], group="TREND DASHBOARD")
tableTextColor    = input(color.white, "Table Text Color", group="TREND DASHBOARD")
tableBgColor      = input(#2A2A2A, "Table Background Color", group="TREND DASHBOARD")
sizeDashboard     = input.string("Normal", "Table Size", ["Large", "Normal", "Small", "Tiny"], group="TREND DASHBOARD")
showRevBands      = input.bool(true, "Show Reversal Bands", group="REVERSAL BANDS")
lenRevBands       = input.int(30, "Length", group="REVERSAL BANDS")
currentPrice = request.security(syminfo.tickerid, timeframe.period, close)
startHour = input.int(8, "Trading Start Hour", group="TIME FILTER")
startMin = input.int(35, "Start time of hour", group="TIME FILTER")
endHour = input.int(20, "Trading End Hour", group="TIME FILTER")
endMin = input.int(30, "End min", group = "TIME FILTER")
var int openBarIndex = 0
var bool tp_1_filled = true
var bool tp_2_filled = true
var bool tp_3_filled = true
var float open_price = 0.00
smoothrng(x, t, m) =>
    wper = t * 2 - 1
    avrng = ta.ema(math.abs(x - x[1]), t)
    smoothrng = ta.ema(avrng, wper) * m
rngfilt(x, r) =>
    rngfilt = x
    rngfilt := x > nz(rngfilt[1]) ? x - r < nz(rngfilt[1]) ? nz(rngfilt[1]) : x - r : x + r > nz(rngfilt[1]) ? nz(rngfilt[1]) : x + r
percWidth(len, perc) => (ta.highest(len) - ta.lowest(len)) * perc / 100
securityNoRep(sym, res, src) => request.security(sym, res, src, barmerge.gaps_off, barmerge.lookahead_on)
swingPoints(prd) =>
    pivHi = ta.pivothigh(prd, prd)
    pivLo = ta.pivotlow (prd, prd)
    last_pivHi = ta.valuewhen(pivHi, pivHi, 1)
    last_pivLo = ta.valuewhen(pivLo, pivLo, 1)
    hh = pivHi and pivHi > last_pivHi ? pivHi : na
    lh = pivHi and pivHi < last_pivHi ? pivHi : na
    hl = pivLo and pivLo > last_pivLo ? pivLo : na
    ll = pivLo and pivLo < last_pivLo ? pivLo : na
    [hh, lh, hl, ll]
f_chartTfInMinutes() =>
    float _resInMinutes = timeframe.multiplier * (
      timeframe.isseconds ? 1                   :
      timeframe.isminutes ? 1.                  :
      timeframe.isdaily   ? 60. * 24            :
      timeframe.isweekly  ? 60. * 24 * 7        :
      timeframe.ismonthly ? 60. * 24 * 30.4375  : na)
f_kc(src, len, sensitivity) =>
    basis = ta.sma(src, len)
    span  = ta.atr(len)
    [basis + span * sensitivity, basis - span * sensitivity]
wavetrend(src, chlLen, avgLen) =>
    esa = ta.ema(src, chlLen)
    d = ta.ema(math.abs(src - esa), chlLen)
    ci = (src - esa) / (0.015 * d)
    wt1 = ta.ema(ci, avgLen)
    wt2 = ta.sma(wt1, 3)
    [wt1, wt2]
f_top_fractal(src) => src[4] < src[2] and src[3] < src[2] and src[2] > src[1] and src[2] > src[0]
f_bot_fractal(src) => src[4] > src[2] and src[3] > src[2] and src[2] < src[1] and src[2] < src[0]
f_fractalize (src) => f_top_fractal(src) ? 1 : f_bot_fractal(src) ? -1 : 0
f_findDivs(src, topLimit, botLimit) =>
    fractalTop = f_fractalize(src) > 0 and src[2] >= topLimit ? src[2] : na
    fractalBot = f_fractalize(src) < 0 and src[2] <= botLimit ? src[2] : na
    highPrev = ta.valuewhen(fractalTop, src[2], 0)[2]
    highPrice = ta.valuewhen(fractalTop, high[2], 0)[2]
    lowPrev = ta.valuewhen(fractalBot, src[2], 0)[2]
    lowPrice = ta.valuewhen(fractalBot, low[2], 0)[2]
    bearSignal = fractalTop and high[2] > highPrice and src[2] < highPrev
    bullSignal = fractalBot and low[2] < lowPrice and src[2] > lowPrev
    [bearSignal, bullSignal]
// Get components
source    = close
smrng1    = smoothrng(source, 27, 1.5)
smrng2    = smoothrng(source, 55, sensitivity)
smrng     = (smrng1 + smrng2) / 2
filt      = rngfilt(source, smrng)
up        = 0.0, up := filt > filt[1] ? nz(up[1]) + 1 : filt < filt[1] ? 0 : nz(up[1])
dn        = 0.0, dn := filt < filt[1] ? nz(dn[1]) + 1 : filt > filt[1] ? 0 : nz(dn[1])
bullCond  = bool(na), bullCond := source > filt and source > source[1] and up > 0 or source > filt and source < source[1] and up > 0
bearCond  = bool(na), bearCond := source < filt and source < source[1] and dn > 0 or source < filt and source > source[1] and dn > 0
lastCond  = 0, lastCond := bullCond ? 1 : bearCond ? -1 : lastCond[1]
bull      = bullCond and lastCond[1] == -1
bear      = bearCond and lastCond[1] == 1
countBull = ta.barssince(bull)
countBear = ta.barssince(bear)
trigger   = nz(countBull, bar_index) < nz(countBear, bar_index) ? 1 : 0
ribbon1   = ta.sma(close, smooth1)
ribbon2   = ta.sma(close, smooth2)
rsi       = ta.rsi(close, 21)
rsiOb     = rsi > 70 and rsi > ta.ema(rsi, 10)
rsiOs     = rsi < 30 and rsi < ta.ema(rsi, 10)
dHigh     = securityNoRep(syminfo.tickerid, "D", high [1])
dLow      = securityNoRep(syminfo.tickerid, "D", low  [1])
dClose    = securityNoRep(syminfo.tickerid, "D", close[1])
ema1      = ta.ema(srcEma1, lenEma1)
ema2      = ta.ema(srcEma2, lenEma2)
ema3      = ta.ema(srcEma3, lenEma3)
[hh, lh, hl, ll] = swingPoints(prdSwing)
ema = ta.ema(close, 144)
emaBull = close > ema
equal_tf(res) => str.tonumber(res) == f_chartTfInMinutes() and not timeframe.isseconds
higher_tf(res) => str.tonumber(res) > f_chartTfInMinutes() or timeframe.isseconds
too_small_tf(res) => (timeframe.isweekly and res=="1") or (timeframe.ismonthly and str.tonumber(res) < 10)
securityNoRep1(sym, res, src) =>
    bool bull_ = na
    bull_ := equal_tf(res) ? src : bull_
    bull_ := higher_tf(res) ? request.security(sym, res, src, barmerge.gaps_off, barmerge.lookahead_on) : bull_
    bull_array = request.security_lower_tf(syminfo.tickerid, higher_tf(res) ? str.tostring(f_chartTfInMinutes()) + (timeframe.isseconds ? "S" : "") : too_small_tf(res) ? (timeframe.isweekly ? "3" : "10") : res, src)
    if array.size(bull_array) > 1 and not equal_tf(res) and not higher_tf(res)
        bull_ := array.pop(bull_array)
    array.clear(bull_array)
    bull_
TF1Bull   = securityNoRep1(syminfo.tickerid, "1"   , emaBull)
TF3Bull   = securityNoRep1(syminfo.tickerid, "3"   , emaBull)
TF5Bull   = securityNoRep1(syminfo.tickerid, "5"   , emaBull)
TF15Bull  = securityNoRep1(syminfo.tickerid, "15"  , emaBull)
TF30Bull  = securityNoRep1(syminfo.tickerid, "30"  , emaBull)
TF60Bull  = securityNoRep1(syminfo.tickerid, "60"  , emaBull)
TF120Bull = securityNoRep1(syminfo.tickerid, "120" , emaBull)
TF240Bull = securityNoRep1(syminfo.tickerid, "240" , emaBull)
TF480Bull = securityNoRep1(syminfo.tickerid, "480" , emaBull)
TFDBull   = securityNoRep1(syminfo.tickerid, "1440", emaBull)
[upperKC1, lowerKC1] = f_kc(close, lenRevBands, 3)
[upperKC2, lowerKC2] = f_kc(close, lenRevBands, 4)
[upperKC3, lowerKC3] = f_kc(close, lenRevBands, 5)
[upperKC4, lowerKC4] = f_kc(close, lenRevBands, 6)
[wt1, wt2] = wavetrend(hlc3, 9, 12)
[wtDivBear1, wtDivBull1] = f_findDivs(wt2, 15, -40)
[wtDivBear2, wtDivBull2] = f_findDivs(wt2, 45, -65)
wtDivBull = wtDivBull1 or wtDivBull2
wtDivBear = wtDivBear1 or wtDivBear2
// Colors
cyan = #00DBFF, cyan30 = color.new(cyan, 70)
pink = #E91E63, pink30 = color.new(pink, 70)
red  = #FF5252, red30  = color.new(red , 70)
isMarketOpen = (hour(time) == startHour  and minute(time) >= startMin) or (hour(time)  > startHour  and (hour(time) < endHour or (hour(time) == endHour and minute(time) <= endMin)) and dayofweek != dayofweek.monday and dayofweek != dayofweek.wednesday and dayofweek != dayofweek.thursday)
if (hour == 15 and minute(time) == 30)
    strategy.close_all("Exit EOD", "Exit EoD")
if (exitEod) 
    if ((hour(time) >= endHour))
        if strategy.position_size != 0
            alert("exit EOD")
        strategy.close_all("EOD")
//and not (hour(time) == 8)

var float exit_size = 0.00
off = percWidth(300, offsetSignal)
// plotshape(showBuySell and bull ? low  - off : na, "Buy Label" , shape.labelup  , location.absolute, cyan, 0, "Buy" , color.white, size=size.normal)

    
// plotshape(showBuySell and bear ? high + off : na, "Sell Label", shape.labeldown, location.absolute, pink, 0, "Sell", color.white, size=size.normal)
// var tb = table.new(position.top_right, 5, 6
//   , bgcolor = #1e222d
//   , border_color = #373a46
//   , border_width = 1
//   , frame_color = #373a46
//   , frame_width = 1)
// if isMarketOpen
//     table.cell(tb, 0, 0, 'UsSpy 🥷\n🟢Online\n'+"💸PNL: "+str.tostring(strategy.openprofit), text_color = color.white, text_size = size.normal)
// else
//     table.cell(tb, 0, 0, 'UsSpy 🥷\n🔴Offline\n'+"💸PNL: "+str.tostring(strategy.openprofit), text_color = color.white, text_size = size.normal)
// table.merge_cells(tb, 0, 0, 4, 0)

lStyle = lineStyle == "Solid" ? line.style_solid : lineStyle == "Dotted" ? line.style_dotted : line.style_dashed
lSize  = labelSize == "small" ? size.small       : labelSize == "normal" ? size.normal       : size.large
dHighLine   = showPdHlc ? line.new(bar_index, dHigh,  bar_index + 1, dHigh , xloc.bar_index, extend.both, lineColor, lStyle, lineWidth) : na, line.delete(dHighLine[1])
dLowLine    = showPdHlc ? line.new(bar_index, dLow ,  bar_index + 1, dLow  , xloc.bar_index, extend.both, lineColor, lStyle, lineWidth) : na, line.delete(dLowLine[1])
dCloseLine  = showPdHlc ? line.new(bar_index, dClose, bar_index + 1, dClose, xloc.bar_index, extend.both, lineColor, lStyle, lineWidth) : na, line.delete(dCloseLine[1])
dHighLabel  = showPdHlc ? label.new(bar_index + 100, dHigh , "P.D.H", xloc.bar_index, yloc.price, #000000, label.style_none, labelColor, lSize) : na, label.delete(dHighLabel[1])
dLowLabel   = showPdHlc ? label.new(bar_index + 100, dLow  , "P.D.L", xloc.bar_index, yloc.price, #000000, label.style_none, labelColor, lSize) : na, label.delete(dLowLabel[1])
dCloseLabel = showPdHlc ? label.new(bar_index + 100, dClose, "P.D.C", xloc.bar_index, yloc.price, #000000, label.style_none, labelColor, lSize) : na, label.delete(dCloseLabel[1])

plotshape(showSwing ? hh : na, "", shape.triangledown, location.abovebar, color.new(color.green, 50), -prdSwing, "HH", colorPos, false)
plotshape(showSwing ? hl : na, "", shape.triangleup  , location.belowbar, color.new(color.green, 50), -prdSwing, "HL", colorPos, false)
plotshape(showSwing ? lh : na, "", shape.triangledown, location.abovebar, color.new(color.red  , 50), -prdSwing, "LH", colorNeg, false)
plotshape(showSwing ? ll : na, "", shape.triangleup  , location.belowbar, color.new(color.red  , 50), -prdSwing, "LL", colorNeg, false)
srcStop = close
// percentStop := percentStop/100
atrBand = srcStop * ((percentStop/100) / 100)
atrStop = trigger ? srcStop - atrBand : srcStop + atrBand
lastTrade(src) => ta.valuewhen(bull or bear, src, 0)
entry_y = lastTrade(srcStop)
var float stop_y = na
var float tp1_y = na
var float tp2_y = na
var float tp3_y = na

volatilityThreshold = input.float(1.5, title="Volatility Threshold", step=0.1) 
atrPeriod = input.int(14, title="ATR Period")
atr = ta.atr(atrPeriod)
isVolatile = atr > volatilityThreshold
ema21 = ta.ema(close, 21)
longAllowed = close > ema21 and close > ema
newDay = ta.change(time("D"))
var int tradesToday = 0
notLowVol = ta.atr(14) > ta.sma(ta.atr(14), 50)

isNewsDay() =>
    y = year(time)
    m = month(time)
    d = dayofmonth(time)
    dow = dayofweek
    cpi = (y == 2023 and ((m==1 and d==12) or (m==2 and d==14) or (m==3 and d==14) or (m==4 and d==11) or (m==5 and d==10) or (m==6 and d==13) or (m==7 and d==12) or (m==8 and d==10) or (m==9 and d==13) or (m==10 and d==11) or (m==11 and d==14) or (m==12 and d==12)))
       or (y == 2024 and ((m==1 and d==11) or (m==2 and d==13) or (m==3 and d==12) or (m==4 and d==10) or (m==5 and d==15) or (m==6 and d==12) or (m==7 and d==10) or (m==8 and d==13) or (m==9 and d==11) or (m==10 and d==10) or (m==11 and d==13) or (m==12 and d==11)))
    fomc = (y == 2023 and ((m==2 and d==1) or (m==3 and d==22) or (m==5 and d==3) or (m==6 and d==14) or (m==7 and d==26) or (m==9 and d==20) or (m==11 and d==1))) or (y == 2024 and ((m==1 and d==31) or (m==3 and d==20) or (m==5 and d==1) or (m==6 and d==12) or (m==7 and d==31) or (m==9 and d==18) or (m==12 and d==11))) or (y == 2025 and ((m==1 and d==29) or (m==3 and d==19) or (m==5 and d==7) or (m==6 and d==18) or (m==7 and d==30)))
    nfp = dow == dayofweek.friday and d <= 7
    ism = (dow != dayofweek.saturday and dow != dayofweek.sunday and d <= 3)
    isQuadWitching = ((m == 3 or m == 6 or m == 9 or m == 12) and dow == dayofweek.friday and d >= 15 and d <= 21)
    earnings = ( (y == 2023 and ((m==1 and d>=23 and d<=27) or (m==4 and d>=24 and d<=28) or (m==7 and d>=24 and d<=28) or (m==10 and d>=23 and d<=27))) or(y == 2024 and ((m==1 and d>=22 and d<=26) or (m==4 and d>=22 and d<=26) or (m==7 and d>=22 and d<=26) or (m==10 and d>=21 and d<=25))))
    cpi or fomc or nfp or ism or isQuadWitching or earnings

canTrade = not isNewsDay()

prevClose = request.security(syminfo.tickerid, "D", close[1])
gapPct = math.abs(open - prevClose) / prevClose
gapThreshold = input.float(0.012, title="Gap % Threshold", step=0.001)  // 1.2% default
avoidGap = gapPct > gapThreshold
vix = request.security("CBOE:VIX", "D", close)
vixThreshold = input.float(21, "VIX Max Threshold")  // Conservative
vixAllowed = vix < vixThreshold
nearPrevHigh = math.abs(close - dHigh) / dHigh < 0.002  // within 0.2%
nearPrevLow = math.abs(close - dLow) / dLow < 0.002
avoidPrevRange = nearPrevHigh or nearPrevLow
insideBar = high <= high[1] and low >= low[1]
inOpeningHour = hour == 9 or (hour == 10 and minute < 30)
sweptHigh = high > dHigh and close < dHigh and inOpeningHour
sweptLow = low < dLow and close > dLow and inOpeningHour
judasSwing = sweptHigh or sweptLow
sweptAndRejected = (sweptHigh and close < open) or (sweptLow and close > open)
waitBarsAfterSweep = sweptAndRejected[1] or sweptAndRejected[2]

isBearOB = close[2] > open[2] and close[1] < open[1] and high <= high[2]
isBullOB = close[2] < open[2] and close[1] > open[1] and low >= low[2]
rejectingBearOB = isBearOB and close < low[2]
rejectingBullOB = isBullOB and close > high[2]
orderBlockRejection = rejectingBearOB or rejectingBullOB 



if not canTrade and not avoidGap and vixAllowed and not avoidPrevRange and not insideBar and not judasSwing and not sweptAndRejected and not waitBarsAfterSweep and not orderBlockRejection
    isMarketOpen := false

if newDay
    tradesToday := 0
if showBuySell and bull and isMarketOpen and emaBull and strategy.opentrades == 0 and not isVolatile  and longAllowed and tradesToday < maxTrades 
    tradesToday += 1
    if (barstate.isconfirmed)
        tp_1_filled := true
        tp_2_filled := true
        tp_3_filled := true
        long_stop = entry_y - (entry_y * percentStop / 100)
        entry_y := close  // Always set entry as the price at entry
        // Calculate both stop types
        atr_val = ta.atr(atrPeriod)
        // stop_percent = entry_y * percentStop / 100
        // stop_atr     = atr_val * atrMultiplier
        // // Final stop is the WORST CASE for a long: the one closest to entry (the greater of the two distances)
        // stop_y := entry_y - math.max(stop_percent, stop_atr)
        tp1_y := (entry_y - lastTrade(atrStop)) * 1 + entry_y
        tp2_y := (entry_y - lastTrade(atrStop)) * 2 + entry_y
        tp3_y := (entry_y - lastTrade(atrStop)) * 3 + entry_y    
        alert("🚀 Long Entry STRIKE price @  "+str.tostring(yloc.price),alert.freq_once_per_bar_close)
        open_price := currentPrice
        exit_size := strategy.position_size/3
        strategy.entry("Buy" , strategy.long)
        openBarIndex := bar_index
        log.info("Buy entry")
// if bull and not emaBull and not isVolatile
//     strategy.close("Sell", "Reversal")
//     log.info("Reversal Buy - Caused by sell")
//     alert("Exit All Positions REVERSAL",alert.freq_once_per_bar_close)

// --- ATR/PERCENT STOP LOSS FOR LONGS (and plotting) ---
if strategy.position_size > 0
    entry_price = strategy.position_avg_price
    atr_val = ta.atr(atrPeriod)
    stop_percent = percentStop > 0 ? entry_price * percentStop / 100 : na
    stop_atr     = atr_val * atrMultiplier
    float stop_dist = na
    if not na(stop_percent) and not na(stop_atr)
        stop_dist := math.min(stop_percent, stop_atr)  // Use the tighter stop (change to max for wider stop)
    else
        stop_dist := na
    stop_y = entry_price - stop_dist

    // Plot stop loss line at correct Y (no need for [1] indexing)
    var line profit_line = na
    var line stop_line = na
    if not na(stop_line) and not na(profit_line)
        line.delete(stop_line)
        line.delete(profit_line)
    if (showProfitLines)
        stop_line := line.new(openBarIndex, stop_y, bar_index + 1, stop_y, color=color.red, width=2, extend=extend.none)
        profit_line := line.new(openBarIndex, tp2_y, bar_index + 1, tp2_y, color=color.green, width=2, extend=extend.none)
    // Label (optional)
    // label.new(bar_index, stop_y, "Stop Loss: " + str.tostring(math.round_to_mintick(stop_y)), color=color.red, style=label.style_label_left, textcolor=color.white)
    // Stop loss check
    if low < stop_y
        strategy.exit("Buy", from_entry="Buy", comment = "SL", limit=stop_y)
        log.info("long sl hit")
        alert("🟥 Long Stop Loss Exit", alert.freq_once_per_bar_close)

shortAllowed = close < ema21 and close < ema
if showBuySell and bear and isMarketOpen and not emaBull and strategy.opentrades == 0 and not isVolatile and shortAllowed and tradesToday < maxTrades 
    tradesToday += 1
    if (barstate.isconfirmed)
        tp_1_filled := true
        tp_2_filled := true
        tp_3_filled := true
        tp1_y := (entry_y - lastTrade(atrStop)) * 1 + entry_y
        tp2_y := (entry_y - lastTrade(atrStop)) * 2 + entry_y
        tp3_y := (entry_y - lastTrade(atrStop)) * 3 + entry_y    
        open_price := currentPrice
        exit_size := strategy.position_size/3
        strategy.entry("Sell", strategy.short)
        log.info("Sell entry")
        openBarIndex := bar_index
        alert("🔻 Short Entry on STRIKE price @  "+str.tostring(yloc.price),alert.freq_once_per_bar_close)
// --- ATR/PERCENT STOP LOSS FOR SHORTS (and plotting) ---
if strategy.position_size < 0
    entry_price = strategy.position_avg_price
    atr_val = ta.atr(atrPeriod)
    stop_percent = percentStop > 0 ? entry_price * percentStop / 100 : na
    stop_atr     = atr_val * atrMultiplier
    float stop_dist = na
    if not na(stop_percent) and not na(stop_atr)
        stop_dist := math.min(stop_percent, stop_atr)  // Use the tighter stop (change to max for wider stop)
    else
        stop_dist := na
    stop_y = entry_price + stop_dist

    // Plot stop loss line at correct Y (no need for [1] indexing)
    var line profit_line = na
    var line stop_line = na
    if not na(stop_line) and not na(profit_line)
        line.delete(stop_line)
        line.delete(profit_line)
    if (showProfitLines)
        stop_line := line.new(openBarIndex, stop_y, bar_index + 1, stop_y, color=color.red, width=2, extend=extend.none)
        profit_line := line.new(openBarIndex, tp2_y, bar_index + 1, tp2_y, color=color.green, width=2, extend=extend.none)

    // Label (optional)
    // Stop loss check
    if high > stop_y
        strategy.exit("Sell", from_entry="Sell", comment = "SL", limit=stop_y)
        log.info("short sl hit")
        alert("🟥 Short Stop Loss Exit", alert.freq_once_per_bar_close)
// if close < stop_y and strategy.position_size > 0 // long
//     strategy.close_all("sl")
//     alert("Exit All Positions SL",alert.freq_once_per_bar_close)
//     log.info("Stop loss triggered - Buy")
     
if high > stop_y and strategy.position_size < 0 // short
    strategy.exit("Sell", from_entry="Sell", comment = "SL", limit=stop_y)
    alert("Exit All Positions SL",alert.freq_once_per_bar_close)
    log.info("Stop loss triggered - Sell")

    // label.new(bar_index + 1, currentPrice, str.tostring(tp_1_filled), xloc.bar_index, yloc.price, color.blue, label.style_label_left, color.white, size.normal)

// LONGs
if close > tp1_y and strategy.position_size > 0 and tp_1_filled
    if (barstate.isconfirmed)
        // strategy.close("Buy", "tp1", qty_percent = 33, immediately = true)
        // strategy.close_all("TP")
        // alert("ONE", alert.freq_once_per_bar)
        log.info("Take profit 1 - Long side")
        tp_1_filled := false

if high > tp2_y and strategy.position_size > 0 and tp_2_filled
    strategy.exit("Buy", from_entry="Buy", comment = "TP", limit=tp2_y)
    alert("FULL TP", alert.freq_once_per_bar)
    log.info("Take profit 2 - Long side")
    tp_2_filled := false
if close > tp3_y and strategy.position_size > 0  and tp_3_filled
    strategy.close_all("tp3", "Buy")
    // alert("THREE", alert.freq_once_per_bar)
    // log.info("Take profit 3 - Long side")
    tp_3_filled := false
if close <= open_price and not tp_1_filled and strategy.position_size > 0
    // strategy.close_all("break-even "+str.tostring(open_price)+str.tostring(currentPrice))
    // alert("BE")
    log.info("BE - Long side")
// SHORT
//
if low < tp2_y and strategy.position_size < 0
    alert("FULL TP", alert.freq_once_per_bar)
    strategy.exit("Sell", from_entry="Sell", comment = "TP", limit=tp2_y)
labelTpSl(y, txt, color) =>
    label labelTpSl = percentStop != 0 ? label.new(bar_index, y, txt, xloc.bar_index, yloc.price, color, label.style_label_left, color.white, size.normal) : na
    label.delete(labelTpSl[1])
// labelTpSl(entry_y, "Entry: " + str.tostring(math.round_to_mintick(entry_y)), color.gray)
// labelTpSl(stop_y , "Stop Loss: " + str.tostring(math.round_to_mintick(stop_y)), color.red)
// labelTpSl(tp1_y, "Take Profit 1: " + str.tostring(math.round_to_mintick(tp1_y)), color.green)
// labelTpSl(tp2_y, "Take Profit " + str.tostring(math.round_to_mintick(tp2_y)), color.green)
// labelTpSl(tp3_y, "Take Profit 3: " + str.tostring(math.round_to_mintick(tp3_y)), color.green)
lineTpSl(y, color) =>
    line lineTpSl = percentStop != 0 ? line.new(bar_index - (trigger ? countBull : countBear) + 4, y, bar_index + 1, y, xloc.bar_index, extend.none, color, line.style_solid) : na
    line.delete(lineTpSl[1])
lineTpSl(entry_y, color.gray)
lineTpSl(stop_y, color.red)
// lineTpSl(tp1_y, color.green)
// lineTpSl(tp2_y, color.green)
// lineTpSl(tp3_y, color.green)
var dashboard_loc  = locationDashboard == "Top Right" ? position.top_right : locationDashboard == "Middle Right" ? position.middle_right : locationDashboard == "Bottom Right" ? position.bottom_right : locationDashboard == "Top Center" ? position.top_center : locationDashboard == "Middle Center" ? position.middle_center : locationDashboard == "Bottom Center" ? position.bottom_center : locationDashboard == "Top Left" ? position.top_left : locationDashboard == "Middle Left" ? position.middle_left : position.bottom_left
var dashboard_size = sizeDashboard == "Large" ? size.large : sizeDashboard == "Normal" ? size.normal : sizeDashboard == "Small" ? size.small : size.tiny
var dashboard      = showDashboard ? table.new(dashboard_loc, 2, 15, tableBgColor, #000000, 2, tableBgColor, 1) : na
dashboard_cell(column, row, txt, signal=false) => table.cell(dashboard, column, row, txt, 0, 0, signal ? #000000 : tableTextColor, text_size=dashboard_size)
dashboard_cell_bg(column, row, col) => table.cell_set_bgcolor(dashboard, column, row, col)
// if showDashboard
//     dashboard_cell(0, 0 , "SpyAlgo 🥷")
//     dashboard_cell(0, 1 , "Current Position")
//     dashboard_cell(0, 2 , "Current Trend")
//     dashboard_cell(0, 3 , "Volume")
//     dashboard_cell(0, 4 , "Timeframe")
//     dashboard_cell(0, 5 , "1 min:")
//     dashboard_cell(0, 6 , "3 min:")
//     dashboard_cell(0, 7 , "5 min:")
//     dashboard_cell(0, 8 , "15 min:")
//     dashboard_cell(0, 9 , "30 min:")
//     dashboard_cell(0, 10, "1 H:")
//     dashboard_cell(0, 11, "2 H:")
//     dashboard_cell(0, 12, "4 H:")
//     dashboard_cell(0, 13, "8 H:")
//     dashboard_cell(0, 14, "Daily:")
//     dashboard_cell(1, 0 , "V.5")
//     dashboard_cell(1, 1 , trigger ? "Buy" : "Sell", true), dashboard_cell_bg(1, 1, trigger ? color.green : color.red)
//     dashboard_cell(1, 2 , emaBull ? "Bullish" : "Bearish", true), dashboard_cell_bg(1, 2, emaBull ? color.green : color.red)
//     dashboard_cell(1, 3 , str.tostring(volume))
//     dashboard_cell(1, 4 , "Trends")
//     dashboard_cell(1, 5 , TF1Bull   ? "Bullish" : "Bearish", true), dashboard_cell_bg(1, 5 , TF1Bull   ? color.green : color.red)
//     dashboard_cell(1, 6 , TF3Bull   ? "Bullish" : "Bearish", true), dashboard_cell_bg(1, 6 , TF3Bull   ? color.green : color.red)
//     dashboard_cell(1, 7 , TF5Bull   ? "Bullish" : "Bearish", true), dashboard_cell_bg(1, 7 , TF5Bull   ? color.green : color.red)
//     dashboard_cell(1, 8 , TF15Bull  ? "Bullish" : "Bearish", true), dashboard_cell_bg(1, 8 , TF15Bull  ? color.green : color.red)
//     dashboard_cell(1, 9 , TF30Bull  ? "Bullish" : "Bearish", true), dashboard_cell_bg(1, 9 , TF30Bull  ? color.green : color.red)
//     dashboard_cell(1, 10, TF60Bull  ? "Bullish" : "Bearish", true), dashboard_cell_bg(1, 10, TF60Bull  ? color.green : color.red)
//     dashboard_cell(1, 11, TF120Bull ? "Bullish" : "Bearish", true), dashboard_cell_bg(1, 11, TF120Bull ? color.green : color.red)
//     dashboard_cell(1, 12, TF240Bull ? "Bullish" : "Bearish", true), dashboard_cell_bg(1, 12, TF240Bull ? color.green : color.red)
//     dashboard_cell(1, 13, TF480Bull ? "Bullish" : "Bearish", true), dashboard_cell_bg(1, 13, TF480Bull ? color.green : color.red)
//     dashboard_cell(1, 14, TFDBull   ? "Bullish" : "Bearish", true), dashboard_cell_bg(1, 14, TFDBull   ? color.green : color.red)

// Alerts
alert01 = ta.crossover(ribbon1, ribbon2)
alert02 = bull
alert03 = wtDivBull
alert04 = wtDivBear
alert05 = bull or bear
alert06 = ta.crossover(wt1, wt2) and wt2 <= -53
alert07 = ta.crossunder(wt1, wt2) and wt2 >= 53
alert08 = ta.crossunder(ribbon1, ribbon2)
alert09 = rsiOb or rsiOs
alert10 = bear
alert11 = ta.cross(ribbon1, ribbon2)
// alerts(sym) =>
//     if alert02 or alert03 or alert04 or alert06 or alert07 or alert10
//         alert_text = alert02 ? "Buy Signal EzAlgo" : alert03 ? "Strong Buy Signal EzAlgo" : alert04 ? "Strong Sell Signal EzAlgo" : alert06 ? "Mild Buy Signal EzAlgo" : alert07 ? "Mild Sell Signal EzAlgo" : "Sell Signal EzAlgo"
//         alert(alert_text,  alert.freq_once_per_bar_close)
// alerts(syminfo.tickerid)
// alertcondition(alert01, "Blue Trend Ribbon Alert", "Blue Trend Ribbon, TimeFrame={{interval}}")
// alertcondition(alert02, "Buy Signal", "Buy Signal EzAlgo")
// alertcondition(alert03, "Divergence Buy Alert", "Strong Buy Signal EzAlgo, TimeFrame={{interval}}")
// alertcondition(alert04, "Divergence Sell Alert", "Strong Sell Signal EzAlgo, TimeFrame={{interval}}")
// alertcondition(alert05, "Either Buy or Sell Signal", "EzAlgo Signal")
// alertcondition(alert06, "Mild Buy Alert", "Mild Buy Signal EzAlgo, TimeFrame={{interval}}")
// alertcondition(alert07, "Mild Sell Alert", "Mild Sell Signal EzAlgo, TimeFrame={{interval}}")
// alertcondition(alert08, "Red Trend Ribbon Alert", "Red Trend Ribbon, TimeFrame={{interval}}")
// alertcondition(alert09, "Reversal Signal", "Reversal Signal")
// alertcondition(alert10, "Sell Signal", "Sell Signal EzAlgo")
// alertcondition(alert11, "Trend Ribbon Color Change Alert", "Trend Ribbon Color Change, TimeFrame={{interval}}")
