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
…upperTL = autoTL ? line.new(x1, _y1 + upDev, x2, _y2 + upDev, xloc.bar_index, extend.none, red) : na
line.delete(upperTL[1])
middleTL = autoTL ? line.new(x1, _y1, x2, _y2, xloc.bar_index, extend.none, color.white) : na
line.delete(middleTL[1])
lowerTL = autoTL ? line.new(x1, _y1 - dnDev, x2, _y2 - dnDev, xloc.bar_index, extend.none, green) : na
line.delete(lowerTL[1])
