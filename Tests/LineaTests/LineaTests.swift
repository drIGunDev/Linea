import Testing
import SwiftUI
@testable import Linea

// MARK: - LinearScale

@Suite("LinearScale")
struct LinearScaleTests {

    @Test func toUnitAndFromUnit() {
        let s = LinearScale(min: 10, max: 20)
        #expect(s.toUnit(10) == 0)
        #expect(s.toUnit(15) == 0.5)
        #expect(s.toUnit(20) == 1)
        #expect(s.fromUnit(0) == 10)
        #expect(s.fromUnit(0.5) == 15)
        #expect(s.fromUnit(1) == 20)
    }

    @Test func toUnitOutsideRange() {
        let s = LinearScale(min: 0, max: 10)
        #expect(s.toUnit(-5) == -0.5)
        #expect(s.toUnit(15) == 1.5)
    }

    @Test func toUnitDegenerateSpan() {
        let s = LinearScale(min: 5, max: 5)
        // span falls back to 1e-12, should not crash
        let u = s.toUnit(5)
        #expect(u.isFinite)
    }

    @Test func pan() {
        let s = LinearScale(min: 0, max: 100)
        s.clampToOriginal = false
        s.pan(by: 10)
        #expect(s.min == 10)
        #expect(s.max == 110)
    }

    @Test func panClampedDoesNotExceedOriginal() {
        let s = LinearScale(min: 0, max: 100)
        s.clampToOriginal = true
        s.pan(by: 50)
        #expect(s.min >= 0)
        #expect(s.max <= 100)
    }

    @Test func zoomIn() {
        let s = LinearScale(min: 0, max: 100)
        s.clampToOriginal = false
        s.zoom(by: 2.0, around: 50)
        #expect(abs(s.min - 25) < 1e-9)
        #expect(abs(s.max - 75) < 1e-9)
    }

    @Test func zoomOutClampedToOriginal() {
        let s = LinearScale(min: 25, max: 75)
        s.setOriginalRange(min: 0, max: 100)
        s.clampToOriginal = true
        s.zoom(by: 0.25, around: 50)
        #expect(s.min == 0)
        #expect(s.max == 100)
    }

    @Test func reset() {
        let s = LinearScale(min: 0, max: 100)
        s.clampToOriginal = false
        s.pan(by: 20)
        s.reset()
        #expect(s.min == 0)
        #expect(s.max == 100)
    }

    @Test func setOriginalRange() {
        let s = LinearScale(min: 0, max: 10)
        s.setOriginalRange(min: -5, max: 15)
        #expect(s.originalMin == -5)
        #expect(s.originalMax == 15)
    }

    @Test func clampSpanExpandsIfTooSmall() {
        let s = LinearScale(min: 49, max: 51)
        s.setOriginalRange(min: 0, max: 100)
        s.clampToOriginal = false
        s.clampSpan(minSpan: 10)
        #expect(abs((s.max - s.min) - 10) < 1e-9)
    }

    @Test func hashEquality() {
        let a = LinearScale(min: 0, max: 10)
        let b = a
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }
}

// MARK: - DataPoint

@Suite("DataPoint")
struct DataPointTests {

    @Test func initAndEquality() {
        let a = DataPoint(x: 1, y: 2)
        let b = DataPoint(x: 1, y: 2)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test func inequality() {
        let a = DataPoint(x: 1, y: 2)
        let b = DataPoint(x: 1, y: 3)
        #expect(a != b)
    }
}

// MARK: - LinearSeries

@Suite("LinearSeries")
struct LinearSeriesTests {

    @Test func versionBasedEquality() {
        let pts = [DataPoint(x: 0, y: 0), DataPoint(x: 1, y: 1)]
        let a = LinearSeries(points: pts, style: SeriesStyle())
        let b = LinearSeries(points: pts, style: SeriesStyle())
        // Different instances → different versions → not equal
        #expect(a != b)
    }

    @Test func mutationBumpsVersion() {
        var s = LinearSeries(points: [DataPoint(x: 0, y: 0)], style: SeriesStyle())
        let copy = s
        s.points.append(DataPoint(x: 1, y: 1))
        #expect(s != copy)
    }

    @Test func cleanRemovesPoints() {
        var s = LinearSeries(points: [DataPoint(x: 0, y: 0), DataPoint(x: 1, y: 1)], style: SeriesStyle())
        s.clean()
        #expect(s.points.isEmpty)
    }
}

// MARK: - NiceTickProvider

@Suite("NiceTickProvider")
struct NiceTickProviderTests {

    @Test func producesTicksInRange() {
        let scale = LinearScale(min: 0, max: 100)
        let ticks = NiceTickProvider().ticks(scale: scale, target: 5)
        #expect(!ticks.isEmpty)
        for t in ticks {
            #expect(t.value >= -50)   // allow some overshoot from rounding
            #expect(t.value <= 150)
        }
    }

    @Test func tickLabelsAreNonEmpty() {
        let scale = LinearScale(min: 0, max: 10)
        let ticks = NiceTickProvider().ticks(scale: scale, target: 5)
        for t in ticks {
            #expect(!t.label.isEmpty)
        }
    }

    @Test func nanScaleReturnsEmpty() {
        let scale = LinearScale(min: .nan, max: 10)
        let ticks = NiceTickProvider().ticks(scale: scale, target: 5)
        #expect(ticks.isEmpty)
    }

    @Test func infinityScaleReturnsEmpty() {
        let scale = LinearScale(min: -.infinity, max: .infinity)
        let ticks = NiceTickProvider().ticks(scale: scale, target: 5)
        #expect(ticks.isEmpty)
    }

    @Test func singleFiniteInfReturnsEmpty() {
        let scale = LinearScale(min: 0, max: .infinity)
        let ticks = NiceTickProvider().ticks(scale: scale, target: 5)
        #expect(ticks.isEmpty)
    }

    @Test func smallRange() {
        let scale = LinearScale(min: 0.001, max: 0.005)
        let ticks = NiceTickProvider().ticks(scale: scale, target: 4)
        #expect(!ticks.isEmpty)
    }

    @Test func negativeRange() {
        let scale = LinearScale(min: -100, max: -10)
        let ticks = NiceTickProvider().ticks(scale: scale, target: 5)
        #expect(!ticks.isEmpty)
        for t in ticks {
            #expect(t.value <= 0)
        }
    }
}

// MARK: - FixedCountTickProvider

@Suite("FixedCountTickProvider")
struct FixedCountTickProviderTests {

    @Test func exactTickCount() {
        let scale = LinearScale(min: 0, max: 10)
        let ticks = FixedCountTickProvider().ticks(scale: scale, target: 5)
        #expect(ticks.count == 6) // 0...target → target+1 values
    }

    @Test func emptyWhenMinEqualsMax() {
        let scale = LinearScale(min: 5, max: 5)
        let ticks = FixedCountTickProvider().ticks(scale: scale, target: 5)
        #expect(ticks.isEmpty)
    }

    @Test func emptyWhenReversed() {
        let scale = LinearScale(min: 10, max: 5)
        let ticks = FixedCountTickProvider().ticks(scale: scale, target: 5)
        #expect(ticks.isEmpty)
    }

    @Test func nanReturnsEmpty() {
        let scale = LinearScale(min: .nan, max: 10)
        let ticks = FixedCountTickProvider().ticks(scale: scale, target: 5)
        #expect(ticks.isEmpty)
    }

    @Test func infinityReturnsEmpty() {
        let scale = LinearScale(min: 0, max: .infinity)
        let ticks = FixedCountTickProvider().ticks(scale: scale, target: 5)
        #expect(ticks.isEmpty)
    }

    @Test func firstAndLastTickMatchBounds() {
        let scale = LinearScale(min: -10, max: 30)
        let ticks = FixedCountTickProvider().ticks(scale: scale, target: 4)
        #expect(abs(ticks.first!.value - (-10)) < 1e-9)
        #expect(abs(ticks.last!.value - 30) < 1e-9)
    }
}

// MARK: - NumberAxisFormatter

@Suite("NumberAxisFormatter")
struct NumberAxisFormatterTests {

    @Test func fixedDecimals() {
        let f = NumberAxisFormatter(decimals: 2)
        let (str, _) = f.string(for: 3.14159)
        #expect(str == "3.14")
    }

    @Test func zeroDecimals() {
        let f = NumberAxisFormatter(decimals: 0)
        let (str, _) = f.string(for: 42.7)
        #expect(str == "43")
    }

    @Test func siPrefixK() {
        let f = NumberAxisFormatter(decimals: 1, useSI: true)
        let (str, _) = f.string(for: 2500)
        #expect(str == "2.5k")
    }

    @Test func siPrefixM() {
        let f = NumberAxisFormatter(decimals: 1, useSI: true)
        let (str, _) = f.string(for: 3_500_000)
        #expect(str == "3.5M")
    }

    @Test func siPrefixNotAppliedBelowThreshold() {
        let f = NumberAxisFormatter(decimals: 1, useSI: true)
        let (str, _) = f.string(for: 500)
        #expect(str == "500.0")
    }

    @Test func negativeWithSI() {
        let f = NumberAxisFormatter(decimals: 0, useSI: true)
        let (str, _) = f.string(for: -2_000_000)
        #expect(str == "-2M")
    }
}

// MARK: - AutoRanger

@Suite("AutoRanger")
struct AutoRangerTests {

    @Test func dataBoundsXFromMultipleSeries() {
        let series: [String: LinearSeries] = [
            "a": LinearSeries(points: [DataPoint(x: 1, y: 0), DataPoint(x: 5, y: 0)], style: SeriesStyle()),
            "b": LinearSeries(points: [DataPoint(x: -2, y: 0), DataPoint(x: 3, y: 0)], style: SeriesStyle()),
        ]
        let bounds = AutoRanger.dataBoundsX(series: series)
        #expect(bounds.min == -2)
        #expect(bounds.max == 5)
    }

    @Test func dataBoundsXEmptySeries() {
        let series: [String: LinearSeries] = [:]
        let bounds = AutoRanger.dataBoundsX(series: series)
        #expect(bounds.min == 0)
        #expect(bounds.max == 1)
    }

    @Test func dataBoundsYSinglePoint() {
        let s = LinearSeries(points: [DataPoint(x: 0, y: 7)], style: SeriesStyle())
        let bounds = AutoRanger.dataBoundsY(seriesArray: [s])
        #expect(bounds.min == 6.5)
        #expect(bounds.max == 7.5)
    }

    @Test func withPadding() {
        let (lo, hi) = AutoRanger.withPadding(min: 10, max: 20, frac: 0.1)
        #expect(abs(lo - 9) < 1e-9)
        #expect(abs(hi - 21) < 1e-9)
    }

    @Test func withPaddingNegativeFrac() {
        let (lo, hi) = AutoRanger.withPadding(min: 10, max: 20, frac: -0.5)
        // negative frac is clamped to 0
        #expect(lo == 10)
        #expect(hi == 20)
    }

    @Test func niceRounding() {
        let (lo, hi) = AutoRanger.nice(min: 0.3, max: 9.7, targetTicks: 5)
        #expect(lo <= 0.3)
        #expect(hi >= 9.7)
        // nice bounds should be round numbers
        #expect(lo == lo.rounded(.down))
    }

    @Test func niceWithZeroSpan() {
        let (lo, hi) = AutoRanger.nice(min: 5, max: 5)
        #expect(lo == 5)
        #expect(hi == 5)
    }
}

// MARK: - Array+Stats

@Suite("Array+Stats")
struct ArrayStatsTests {

    @Test func minMaxNormal() {
        let (mn, mx) = [3.0, 1.0, 4.0, 1.0, 5.0].minMax()
        #expect(mn == 1.0)
        #expect(mx == 5.0)
    }

    @Test func minMaxEmpty() {
        let (mn, mx) = [Double]().minMax()
        #expect(mn == 0)
        #expect(mx == 1)
    }

    @Test func minMaxSingleElement() {
        let (mn, mx) = [42.0].minMax()
        #expect(mn == 42.0)
        #expect(mx == 43.0) // mn == mx → mx = mn + 1
    }

    @Test func minMaxAllEqual() {
        let (mn, mx) = [7.0, 7.0, 7.0].minMax()
        #expect(mn == 7.0)
        #expect(mx == 8.0)
    }
}

// MARK: - Axis / YAxes

@Suite("Axis")
struct AxisTests {

    @Test func xAxisResolveRange() {
        let xAxis = XAxis()
        let series: [String: LinearSeries] = [
            "s1": LinearSeries(points: [DataPoint(x: 0, y: 0), DataPoint(x: 100, y: 50)], style: SeriesStyle()),
        ]
        xAxis.resolveRange(series: series, targetTicks: 5, resetOriginalRange: true)
        #expect(xAxis.scale.min <= 0)
        #expect(xAxis.scale.max >= 100)
    }

    @Test func yAxesResolveWithExplicitBinding() {
        let yAxis = YAxis(side: .left)
        let binding = AxisBinding<String>(axis: yAxis, seriesIds: ["s1"])
        let yAxes = YAxes(bindings: [binding])
        let series: [String: LinearSeries] = [
            "s1": LinearSeries(points: [DataPoint(x: 0, y: -10), DataPoint(x: 1, y: 30)], style: SeriesStyle()),
            "s2": LinearSeries(points: [DataPoint(x: 0, y: 0), DataPoint(x: 1, y: 1000)], style: SeriesStyle()),
        ]
        yAxes.resolveRange(series: series, targetTicks: 5, resetOriginalRange: true)
        // Only s1 should determine the range, not s2
        #expect(yAxis.scale.max < 500)
    }

    @Test func yAxesResolveWithEmptyBinding() {
        let yAxis = YAxis(side: .left)
        let binding = AxisBinding<String>(axis: yAxis, seriesIds: [])
        let yAxes = YAxes(bindings: [binding])
        let series: [String: LinearSeries] = [
            "s1": LinearSeries(points: [DataPoint(x: 0, y: 5), DataPoint(x: 1, y: 15)], style: SeriesStyle()),
        ]
        yAxes.resolveRange(series: series, targetTicks: 5, resetOriginalRange: true)
        // Empty binding → should use all series
        #expect(yAxis.scale.min <= 5)
        #expect(yAxis.scale.max >= 15)
    }

    @Test func yAxisSide() {
        let left = YAxis(side: .left)
        let right = YAxis(side: .right)
        #expect(left.side == .left)
        #expect(right.side == .right)
    }

    @Test func bindFluentAPI() {
        let yAxes = YAxes<String>.bind(axis: YAxis(), to: ["a", "b"])
        #expect(yAxes.bindings.count == 1)
        #expect(yAxes.bindings[0].seriesIds == ["a", "b"])
    }

    @Test func chainedBind() {
        let yAxes = YAxes<String>
            .bind(axis: YAxis(side: .left), to: ["a"])
            .bind(axis: YAxis(side: .right), to: ["b"])
        #expect(yAxes.bindings.count == 2)
    }

    @Test func fixedAutoRange() {
        let axis = XAxis(autoRange: .fixed(min: -10, max: 10))
        let series: [String: LinearSeries] = [
            "s1": LinearSeries(points: [DataPoint(x: 0, y: 0), DataPoint(x: 100, y: 0)], style: SeriesStyle()),
        ]
        axis.resolveRange(series: series, targetTicks: 5, resetOriginalRange: true)
        #expect(axis.scale.min == -10)
        #expect(axis.scale.max == 10)
    }

    @Test func noneAutoRangeUsesRawBounds() {
        let axis = XAxis(autoRange: .none)
        let series: [String: LinearSeries] = [
            "s1": LinearSeries(points: [DataPoint(x: 3, y: 0), DataPoint(x: 97, y: 0)], style: SeriesStyle()),
        ]
        axis.resolveRange(series: series, targetTicks: 5, resetOriginalRange: true)
        // .none uses raw data bounds without padding or nice rounding
        #expect(axis.scale.min == 3)
        #expect(axis.scale.max == 97)
    }
}

// MARK: - SeriesStyle

@Suite("SeriesStyle")
struct SeriesStyleTests {

    @Test func defaults() {
        let s = SeriesStyle()
        #expect(s.lineWidth == 2)
        #expect(s.opacity == 1)
        #expect(s.dash == nil)
        #expect(s.fill == nil)
        #expect(s.smoothing == .none)
    }

    @Test func customInit() {
        let s = SeriesStyle(
            color: .red,
            lineWidth: 3,
            opacity: 0.5,
            dash: [5, 3],
            fill: .blue,
            smoothing: .catmullRom(0.5)
        )
        #expect(s.lineWidth == 3)
        #expect(s.opacity == 0.5)
        #expect(s.dash == [5, 3])
        #expect(s.smoothing == .catmullRom(0.5))
    }

    @Test func smoothingEquality() {
        #expect(Smoothing.none == Smoothing.none)
        #expect(Smoothing.catmullRom(0.5) == Smoothing.catmullRom(0.5))
        #expect(Smoothing.catmullRom(0.5) != Smoothing.catmullRom(0.8))
        #expect(Smoothing.monotoneCubic == Smoothing.monotoneCubic)
        #expect(Smoothing.none != Smoothing.monotoneCubic)
    }
}
