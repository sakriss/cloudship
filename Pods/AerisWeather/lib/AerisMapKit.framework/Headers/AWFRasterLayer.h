//
//  AWFMapLayer.h
//  AerisMapKit
//
//  Created by Nicholas Shipes on 7/19/17.
//  Copyright © 2017 AerisWeather, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AerisMapKit/AWFMapLayer.h>

NS_ASSUME_NONNULL_BEGIN

//-----------------------------------------------------------------------------
// @name Radar & Satellite
//-----------------------------------------------------------------------------

/**
 Current and past preciptiation-type radar.
 
 Use `AWFMapLayerFutureRadar` for the future/forecast layer associated with this type.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerRadar;

/**
 Black and white visible satellite. This layer uses a non-transparent black background.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerSatelliteVisible;

/**
 Geocolor satellite.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerSatelliteGeocolor;

/**
 Black and white infrared satellite.
 
 Use `AWFMapLayerFutureSatellite` for the future/forecast layer associated with this type.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerSatellite;

/**
 Color-enhanced infrared satellite for the Continental US region.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerSatelliteInfraredColorUS;

/**
 Color-enhanced infrared satellite.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerSatelliteInfraredColor;

/**
 Color-enhanced water vapor satellite.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerSatelliteWaterVapor;

/**
 Black and white visible satellite.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerSatelliteVisibleTransparent;

//-----------------------------------------------------------------------------
// @name Forecasts
//-----------------------------------------------------------------------------

/**
 Forecast simulated radar.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureRadar;

/**
 Forecast simulated satellite and cloud cover.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureSatellite;

/**
 Forecast surface temperatures.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureTemperatures;

/**
 Forecast precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFuturePrecip;

/**
 Forecast precipitation at 1-hour intervals.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFuturePrecip1Hour;

/**
 Forecast precipitation at 6-hour intervals.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFuturePrecip6Hour;

/**
 Forecast surface dew points.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureDewPoints;

/**
 Forecast surface humidity.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureHumidity;

/**
 Forecast surface wind speeds.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureWindSpeeds;

/**
 Forecast jet stream.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureJetStream;

/**
 Forecast surface wind gusts.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureWindGusts;

/**
 Forecast feels like temperature.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureFeelsLike;

/**
 Forecast surface heat index.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureHeatIndex;

/**
 Forecast surface wind chill.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureWindChill;

/**
 Forecast snow accumulation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureSnowAccumulation;

/**
 Forecast ground snow depth.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureSnowDepth;

/**
 Forecast ice accumulation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureIceAccumulation;

/**
 Forecast surface high temperatures.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureTemperaturesMax;

/**
 Forecast surface low temperatures.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureTemperaturesMin;

/**
 Forecast surface visibility.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureVisibility;

/**
 Mean sea level surface pressure.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureSurfacePressure;

/**
 Mean sea level surface pressure as isobars.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureSurfacePressureIsobars;

/**
 Forecast road conditions based on expected precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureRoadConditions;

/**
 Forecast midterm road conditions based on expected precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureRoadConditionsMidterm;

/**
 Forecast road condition index based on expected precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureRoadConditionsIndex;

/**
 Forecast midterm road condition index based on expected precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFutureRoadConditionsIndexMidterm;

//-----------------------------------------------------------------------------
// @name Tropical
//-----------------------------------------------------------------------------

/**
 Active tropical cyclone names
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerTropicalCyclonesNames;

/**
 Active tropical cyclone positions
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerTropicalCyclonesPositions;

/**
 Active tropical cyclone positions as icons
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerTropicalCyclonesPositionIcons;

/**
 Active tropical cyclone tracks as polylines
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerTropicalCyclonesTrackLines;

/**
 Active tropical cyclone tracks as points
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerTropicalCyclonesTrackPoints;

/**
 Active tropical cyclone tracks as icons
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerTropicalCyclonesTrackPointIcons;

/**
 Forecast error cone for the forecast track of an active tropical cyclone
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerTropicalCyclonesForecastErrorCones;

/**
 Forecast track of a tropical cyclone as a polyline
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerTropicalCyclonesForecastLines;

/**
 Forecast track of a tropical cyclone as points
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerTropicalCyclonesForecastPoints;

/**
 Forecast track of a tropical cyclone as icons
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerTropicalCyclonesForecastPointIcons;

/**
 Coastal areas under cyclone watches or warnings
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerTropicalCyclonesBreakPoints;

//-----------------------------------------------------------------------------
// @name Severe Weather
//-----------------------------------------------------------------------------

/**
 Cloud-to-ground lightning strikes in the last 5 minutes.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerLightningStrikes5Minute;

/**
 Cloud-to-ground lightning strikes in the last 15 minutes.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerLightningStrikes15Minute;

/**
 Cloud-to-ground lightning strikes in the last 5 minutes.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerLightningStrikes5MinuteIcons;

/**
 Cloud-to-ground lightning strikes in the last 15 minutes.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerLightningStrikes15MinuteIcons;

/**
 Lightning strike density measured as the number of lightning strikes per square meter per second.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerLightningStrikeDensity;

/**
 Active weather alerts and advisories.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerAdvisories;

//-----------------------------------------------------------------------------
// @name Observations
//-----------------------------------------------------------------------------

/**
 Observed surface temperatures.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerTemperatures;

/**
 Observed surface dew points.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerDewPoints;

/**
 Observed surface humidity.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerHumidity;

/**
 Observed surface wind speeds.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerWindSpeeds;

/**
 Observed surface wind direction.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerWindDirection;

/**
 Observed surface wind gusts.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerWindGusts;

/**
 Surface wind chill. This value is only shown when surface temperatures are below 50 degrees Fahrenheit.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerWindChill;

/**
 Surface heat index. This value is only shown when surface temperatures are at or above 80 degrees Fahrenheit.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerHeatIndex;

/**
 Surface feels like temperature. This value is either the actual temperature, wind chill or heat index value depending on conditions.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFeelsLike;

/**
 1-hour observed precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecip1Hour;

/**
 1-day observed precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecip1Day;

/**
 7-day observed precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecip7Day;

/**
 14-day observed precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecip14Day;

/**
 30-day observed precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecip30Day;

/**
 60-day observed precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecip60Day;

/**
 90-day observed precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecip90Day;

/**
 180-day observed precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecip180Day;

/**
 Observed precipitation for the current month to date.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipMTD;

/**
 Observed precipitation for the current year to date.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipYTD;

/**
 Observed precipitation for the current water year to date.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipWYTD;

/**
 Observed precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecip;

/**
 1-day normal precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipNormals1Day;

/**
 7-day normal precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipNormals7Day;

/**
 14-day normal precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipNormals14Day;

/**
 30-day normal precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipNormals30Day;

/**
 60-day normal precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipNormals60Day;

/**
 90-day normal precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipNormals90Day;

/**
 180-day normal precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipNormals180Day;

/**
 Normal precipitation for the current month to date.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipNormalsMTD;

/**
 Normal precipitation for the current year to date.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipNormalsYTD;

/**
 Normal precipitation for the current water year to date.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipNormalsWYTD;

/**
 Normal precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipNormals;

/**
 1-day precipitation departure from normal.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepart1Day;

/**
 7-day precipitation departure from normal.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepart7Day;

/**
 14-day precipitation departure from normal.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepart14Day;

/**
 30-day precipitation departure from normal.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepart30Day;

/**
 60-day precipitation departure from normal.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepart60Day;

/**
 90-day precipitation departure from normal.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepart90Day;

/**
 180-day precipitation departure from normal.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepart180Day;

/**
 Precipitation departure from normal for the current month to date.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepartMTD;

/**
 Precipitation departure from normal for the current year to date.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepartYTD;

/**
 Precipitation departure from normal for the current water year to date.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepartWYTD;

/**
 Precipitation departure from normal.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepart;

/**
 1-day precipitation departure from normal as a percentage.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepartPercent1Day;

/**
 7-day precipitation departure from normal as a percentage.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepartPercent7Day;

/**
 14-day precipitation departure from normal as a percentage.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepartPercent14Day;

/**
 30-day precipitation departure from normal as a percentage.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepartPercent30Day;

/**
 60-day precipitation departure from normal as a percentage.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepartPercent60Day;

/**
 90-day precipitation departure from normal as a percentage.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepartPercent90Day;

/**
 180-day precipitation departure from normal as a percentage.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepartPercent180Day;

/**
 Precipitation departure from normal for the current month to date as a percentage.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepartPercentMTD;

/**
 Precipitation departure from normal for the current year to date as a percentage.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepartPercentYTD;

/**
 Precipitation departure from normal for the current water year to date as a percentage.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepartPercentWYTD;

/**
 Precipitation departure from normal as a percentage.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipDepartPercent;

/**
 
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerCloudCover;

/**
 Estimated ground snow depth.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerSnowDepth;

/**
 Global estimated ground snow depth.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerSnowDepthGlobal;

/**
 Surface visibility.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerVisibility;

//-----------------------------------------------------------------------------
// @name Outlooks
//-----------------------------------------------------------------------------

/**
 Fire outlook for fires caused by dry lightning.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerFiresDryLightningOutlook;

/**
 CPC 6-10 day outlook for above/below normal temperatures.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerTempOutlook6To10Day;

/**
 CPC 6-10 day outlook for above/below normal precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipOutlook6To10Day;

/**
 CPC 8-14 day outlook for above/below normal temperatures.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerTempOutlook8To14Day;

/**
 CPC 8-14 day outlook for above/below normal precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerPrecipOutlook8To14Day;

//-----------------------------------------------------------------------------
// @name Ocean Data
//-----------------------------------------------------------------------------

/**
 Sea chlorophyll concentrations.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerChlorophyll;

/**
 Sea surface temperatures.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerSeaSurfaceTemps;

//-----------------------------------------------------------------------------
// @name Road Conditions
//-----------------------------------------------------------------------------

/**
 Road conditions based on current and recent precipitation.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerRoadConditions;

//-----------------------------------------------------------------------------
// @name Base Map
//-----------------------------------------------------------------------------

/**
 Flat base map. Available in light and dark themes.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerBaseFlat;

/**
 Base map using NASA Blue Marble surface imagery.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerBaseBlueMarble;

/**
 Shaded terrain base map.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerBaseTerrain;

//-----------------------------------------------------------------------------
// @name Overlays
//-----------------------------------------------------------------------------

/**
 Overlay consisting of administration boundaries and labels, including labels for countries, states and major cities.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerOverlayAdmin;

/**
 Overlay consisting of administration boundaries and labels with emphasis on city labels versus state/country labels.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerOverlayAdminCities;

/**
 Overlay consisting of state/province outlines only.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerOverlayStatesOutlines;

/**
 Overlay consisting of state/province outlines and text labels.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerOverlayStates;

/**
 Overlay consisting of county/parish outlines within the US.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerOverlayCounties;

/**
 Overlay consisting of US interstate highways.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerOverlayInterstates;

/**
 Overlay consisting of primary and secondary roads.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerOverlayRoads;

/**
 Overlay consisting of rivers.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerOverlayRivers;

//-----------------------------------------------------------------------------
// @name Layer Masks
//-----------------------------------------------------------------------------

/**
 Mask using the flat base map theme that renders bodies of water transparent.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerMaskLandFlat;

/**
 Mask using the Blue Marble base map theme that renders bodies of water transparent.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerMaskLandBlueMarble;

/**
 Mask using the shaded terrain base map theme that renders bodies of water transparent.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerMaskLandTerrain;

/**
 Mask using the flat base map theme that renders land transparent.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerMaskWaterFlat;

/**
 Mask using the Bathymetry ocean theme that renders land transparent.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerMaskWaterDepth;

/**
 Mask using the flat base map theme that renders everything other than the US transparent.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerMaskLandUSFlat;

/**
 Mask using the flat base map theme that only renders the US transparent.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerMaskClipUSFlat;

/**
 Mask using the Blue Marble map theme that only renders the US transparent.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerMaskClipUSBlueMarble;

/**
 Mask using the shaded terrain map theme that only renders the US transparent.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerMaskClipUSTerrain;

//-----------------------------------------------------------------------------
// @name AMP Point/Shape Layers
//-----------------------------------------------------------------------------

/**
 Current and future convective outlooks using the raster AMP layer.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerAmpConvectiveOutlook;

/**
 Current and past drought index using the raster AMP layer.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerAmpDroughtIndex;

/**
 
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerAmpFireOutlook;

/**
 Displays lightning strikes on a weather map using the raster AMP layer. Using this layer instead of `AWFMapLayerStormCells` does not allow interacting
 with the points as you would when selecting an annotation associated with the point layer.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerAmpLightningStrikes;

/**
 Displays storm cells on a weather map using the raster AMP layer. Using this layer instead of `AWFMapLayerStormCells` does not allow interacting with the
 points as you would when selecting an annotation associated with the point layer.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerAmpStormCells;

/**
 Displays storm reports on a weather map using the raster AMP layer. Using this layer instead of `AWFMapLayerStormCells` does not allow interacting with the
 points as you would when selecting an annotation associated with the point layer.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerAmpStormReports;

/**
 Active tropical cyclones and tracks using the raster AMP layer. Using this layer instead of `AWFMapLayerTropicalCyclones` does not allow interactive with
 the points as you would when selecting an annotation associated with the point layer.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerAmpTropicalCyclones;

/**
 Current severe weather warnings using the raster AMP layer.
 */
FOUNDATION_EXPORT AWFMapLayer const AWFMapLayerAmpWarnings;

/**
 Prefix used for all future data layers.
 */
FOUNDATION_EXPORT NSString * const AWFFutureLayerPrefix;

NS_ASSUME_NONNULL_END
