//@version=5
strategy("Helium 🎈 V 6.7.0 US30", overlay=true, precision=0, explicit_plot_zorder=true, max_labels_count=500)
var bool alertTriggered = false
var bool reverse = false
var bool swinging_allowed = true
var float sl = 0.00
var bool useMarketHrs = false
var int dailyOrderCount = 0  // Counter for daily orders
var bool canTradeToday = true  
// Get user input
isFriday = dayofweek(time) == 6

isMarketOpen = (hour >= 11 and hour <= 14) 
//(hour >= 11 and hour <= 14) 

var tb = table.new(position.top_right, 5, 6
  , bgcolor = #1e222d
  , border_color = #373a46
  , border_width = 1
  , frame_color = #373a46
  , frame_width = 1)
if isMarketOpen
    table.cell(tb, 0, 0, 'Helium 🎈\n🟢Online\n'+"💸PNL: "+str.tostring(strategy.openprofit), text_color = color.white, text_size = size.normal)
else
    table.cell(tb, 0, 0, 'Helium 🎈\n🔴Offline\n'+"💸PNL: "+str.tostring(strategy.openprofit), text_color = color.white, text_size = size.normal)
table.merge_cells(tb, 0, 0, 4, 0)
sensitivity = input.string("Low", "Sensitivity", ["Low", "Medium", "High", "Custom"])
sensitivty_custom = input.float(0.00, "Custom sensitivity value",step=0.01, minval=0, maxval=10)
suppRes     = input.bool(false, "Support & Resistance")
breaks      = input.bool(false, "Breaks")
usePsar     = input.bool(false, "PSAR")
emaEnergy   = input.bool(true, "EMA Energy")
channelBal  = input.bool(true, "Channel Balance")
autoTL      = input.bool(false, "Auto Trend Lines")
orderLimit = input.int(3, "Max Orders per Day", minval=1)  // User-set limit
limitOrders = input.bool(true, "Limit Orders Per Day")  // Toggle for limiting orders
if (ta.change(time("D")))
    dailyOrderCount := 0
    canTradeToday := true
canTradeToday := dailyOrderCount < orderLimit

// Functions
supertrend(_src, factor, atrLen) =>
	atr = ta.atr(atrLen)
	upperBand = _src + factor * atr
	lowerBand = _src - factor * atr
	prevLowerBand = nz(lowerBand[1])
	prevUpperBand = nz(upperBand[1])
	lowerBand := lowerBand > prevLowerBand or close[1] < prevLowerBand ? lowerBand : prevLowerBand
	upperBand := upperBand < prevUpperBand or close[1] > prevUpperBand ? upperBand : prevUpperBand
	int direction = na
	float superTrend = na
	prevSuperTrend = superTrend[1]
	if na(atr[1])
		direction := 1
	else if prevSuperTrend == prevUpperBand
		direction := close > upperBand ? -1 : 1
	else
		direction := close < lowerBand ? 1 : -1
	superTrend := direction == -1 ? lowerBand : upperBand
	[superTrend, direction]
lr_slope(_src, _len) =>
    x = 0.0, y = 0.0, x2 = 0.0, xy = 0.0
    for i = 0 to _len - 1
        val = _src[i]
        per = i + 1
        x += per
        y += val
        x2 += per * per
        xy += val * per
    _slp = (_len * xy - x * y) / (_len * x2 - x * x)
    _avg = y / _len
    _int = _avg - _slp * x / _len + _slp
    [_slp, _avg, _int]
lr_dev(_src, _len, _slp, _avg, _int) =>
    upDev = 0.0, dnDev = 0.0
    val = _int
    for j = 0 to _len - 1
        price = high[j] - val
        if price > upDev
            upDev := price
        price := val - low[j]
        if price > dnDev
            dnDev := price
        price := _src[j]
        val += _slp
    [upDev, dnDev]
// Get Components
ocAvg       = math.avg(open, close)
sma1        = ta.sma(close, 5)
sma2        = ta.sma(close, 6)
sma3        = ta.sma(close, 7)
sma4        = ta.sma(close, 8)
sma5        = ta.sma(close, 9)
sma6        = ta.sma(close, 10)
sma7        = ta.sma(close, 11)
sma8        = ta.sma(close, 12)
sma9        = ta.sma(close, 13)
sma10       = ta.sma(close, 14)
sma11       = ta.sma(close, 15)
sma12       = ta.sma(close, 16)
sma13       = ta.sma(close, 17)
sma14       = ta.sma(close, 18)
sma15       = ta.sma(close, 19)
sma16       = ta.sma(close, 20)
psar        = ta.sar(0.09, 0.11, 1)
[middleKC1, upperKC1, lowerKC1] = ta.kc(close, 80, 10.5)
[middleKC2, upperKC2, lowerKC2] = ta.kc(close, 80, 9.5)
// Calculate Keltner Channels with different parameters
[middleKC3, upperKC3, lowerKC3] = ta.kc(close, 80, 8)
[middleKC4, upperKC4, lowerKC4] = ta.kc(close, 80, 3)

// Calculate Supertrend with different sensitivity levels
[supertrend, direction] = supertrend(close,  sensitivity == "Custom" ? sensitivty_custom : sensitivity == "Low" ? 5 : sensitivity == "Medium" ? 2.5 : 2, 11)

// Calculate Pivot High and Pivot Low
barsL       = 10
barsR       = 10
pivotHigh = fixnan(ta.pivothigh(barsL, barsR)[1])
pivotLow = fixnan(ta.pivotlow(barsL, barsR)[1])

// Calculate Linear Regression Slope and Deviation
source = close, period = 150
[s, a, i] = lr_slope(source, period)
[upDev, dnDev] = lr_dev(source, period, s, a, i)

// Define color variables
green       = #ffffff, green2   = #ffffff
red         = #2196f3, red2     = #2196f3

// Define function to determine EMA energy color
emaEnergyColor(ma) => emaEnergy ? (close >= ma ? green : red) : na

// Plot Keltner Channels with EMA
k1 = plot(ta.ema(upperKC1, 50), "", na, editable=false)
k2 = plot(ta.ema(upperKC2, 50), "", na, editable=false)
k3 = plot(ta.ema(upperKC3, 50), "", na, editable=false)
k4 = plot(ta.ema(upperKC4, 50), "", na, editable=false)
k5 = plot(ta.ema(lowerKC4, 50), "", na, editable=false)
k6 = plot(ta.ema(lowerKC3, 50), "", na, editable=false)
k7 = plot(ta.ema(lowerKC2, 50), "", na, editable=false)
k8 = plot(ta.ema(lowerKC1, 50), "", na, editable=false)
rsi = ta.rsi(close,14)
// Fill Keltner Channels with color
fill(k1, k2, channelBal ? color.new(red2, 40) : na, editable=false)
fill(k2, k3, channelBal ? color.new(red2, 65) : na, editable=false)
fill(k3, k4, channelBal ? color.new(red2, 90) : na, editable=false)
fill(k5, k6, channelBal ? color.new(green2, 90) : na, editable=false)
fill(k6, k7, channelBal ? color.new(green2, 65) : na, editable=false)
fill(k7, k8, channelBal ? color.new(green2, 40) : na, editable=false)

// Calculate VWAP
vwap = ta.vwap(close)

// Define entry conditions
bullishCondition = ta.crossover(close, supertrend) and close >= sma9
bearishCondition = ta.crossunder(close, supertrend) and close <= sma9

// Define additional entry filters
uptrend = ta.crossover(sma1, sma2) and ta.crossover(sma2, sma3) and ta.crossover(sma3, sma4)
downtrend = ta.crossunder(sma1, sma2) and ta.crossunder(sma2, sma3) and ta.crossunder(sma3, sma4)

// Avoid trading against the major trend
bullishCondition := bullishCondition and uptrend
bearishCondition := bearishCondition and downtrend

// Define entry orders
// Calculate bands around VWAP
bandOffset = input.float(0.05, "Band Offset (%)", step=0.01, minval=0, maxval=10) / 100
upperBand = vwap * (1 + bandOffset)
lowerBand = vwap * (1 - bandOffset)

// Plot moving averages with EMA energy color
plot(sma1, "", emaEnergyColor(sma1), editable=false)
plot(sma2, "", emaEnergyColor(sma2), editable=false)
plot(sma3, "", emaEnergyColor(sma3), editable=false)
plot(sma4, "", emaEnergyColor(sma4), editable=false)
plot(sma5, "", emaEnergyColor(sma5), editable=false)
plot(sma6, "", emaEnergyColor(sma6), editable=false)
plot(sma7, "", emaEnergyColor(sma7), editable=false)
plot(sma8, "", emaEnergyColor(sma8), editable=false)
plot(sma9, "", emaEnergyColor(sma9), editable=false)
plot(sma10, "", emaEnergyColor(sma10), editable=false)
plot(sma11, "", emaEnergyColor(sma11), editable=false)
plot(sma12, "", emaEnergyColor(sma12), editable=false)

// Color bars based on Supertrend
barcolor(close > supertrend ? #ecb243 : red2)

// Plot PSAR with color
p3 = plot(ocAvg, "", na, editable=false)
p4 = plot(psar, "PSAR", usePsar ? (close > psar ? green : red) : na, 1, plot.style_circles, editable=false)
fill(p3, p4, usePsar ? (close > psar ? color.new(green, 90) : color.new(red, 90)) : na, editable=false)
symbolToTrack = "US30"
openPrice = request.security(symbolToTrack, "D", open)

// Get the close prices for the specified symbol
percentageDifference = ((close - openPrice) / openPrice) * 100

// Determine if the symbol is up or down intraday
isUpIntraday = close > openPrice
// Plot buy and sell labels
y1 = low - (ta.atr(30) * 2), y1B = low - ta.atr(30)
y2 = high + (ta.atr(30) * 2), y2B = high + ta.atr(30)
bull = ta.crossover(close, supertrend) and close >= sma9 and isMarketOpen  
bear = ta.crossunder(close, supertrend) and close <= sma9 and isMarketOpen 
buy  = bull ? label.new(bar_index, y1, "🎈"+str.tostring(rsi), xloc.bar_index, yloc.price, green, label.style_label_up, color.black) : na
sell = bear ? label.new(bar_index, y2, "💥"+str.tostring(rsi), xloc.bar_index, yloc.price, red2, label.style_label_down, color.white) : na

// Check if market is open and create entry orders
if isFriday and hour == 16
    strategy.close_all()
    alert("Exit Weekend")

// Define the ticker sym

if (isMarketOpen)
    if (bull and not na(buy) and not alertTriggered and canTradeToday and limitOrders)
        if reverse
            strategy.entry("Sell", strategy.short)
        else
            strategy.entry("Buy @"+str.tostring(close), strategy.long)
        alert("New Buy Label Created @ "+str.tostring(close), alert.freq_once_per_bar_close)
        alertTriggered := true
        dailyOrderCount += 1  // Increment order count
    else if not bull
        alertTriggered := false
    if (bear and not na(sell) and not alertTriggered and canTradeToday and limitOrders)
        if reverse
            strategy.entry("Buy @"+str.tostring(close), strategy.long)
        else
            strategy.entry("Sell @"+str.tostring(close), strategy.short)
        alert("New Sell Label Created @"+str.tostring(close), alert.freq_once_per_bar_close)
        alertTriggered := true
        dailyOrderCount += 1  // Increment order count
    else if not bear
        alertTriggered := false
else
    if not swinging_allowed
        strategy.close_all("EOD")
// Plot Pivot High and Pivot Low
plot(pivotHigh, "Resistance", not suppRes or ta.change(pivotHigh) ? na : red, 2, offset=-(barsR + 1), editable=false)
plot(pivotLow, "Support", not suppRes or ta.change(pivotLow) ? na : green, 2, offset=-(barsR + 1), editable=false)

// Plot breakout labels
upB = breaks and ta.crossover(close, pivotHigh) ? label.new(bar_index, y1B, "B", xloc.bar_index, yloc.price, green, label.style_label_up, color.white, size.small) : na
dnB = breaks and ta.crossunder(close, pivotLow) ? label.new(bar_index, y2B, "B", xloc.bar_index, yloc.price, red, label.style_label_down, color.white, size.small) : na

// Plot Linear Regression Trendlines
x1 = bar_index - period + 1, _y1 = i + s * (period - 1), x2 = bar_index, _y2 = i
upperTL = autoTL ? line.new(x1, _y1 + upDev, x2, _y2 + upDev, xloc.bar_index, extend.none, red) : na
line.delete(upperTL[1])
middleTL = autoTL ? line.new(x1, _y1, x2, _y2, xloc.bar_index, extend.none, color.white) : na
line.delete(middleTL[1])
lowerTL = autoTL ? line.new(x1, _y1 - dnDev, x2, _y2 - dnDev, xloc.bar_index, extend.none, green) : na
line.delete(lowerTL[1])
