// ignore_for_file: prefer_const_constructors

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/weather_class.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentAddress = "No Location";
  bool isLoading = false;
  List<WeatherData> _filteredWeatherData = [];

  @override
  void initState() {
    super.initState();
    _getMyLocationWeather();
  }

  void _processWeatherData(List<dynamic> weatherList) {
    Map<String, WeatherData> dailyWeatherData = {};

    for (var item in weatherList) {
      String date = item['dt_txt'].toString().split(' ')[0];
      if (!dailyWeatherData.containsKey(date)) {
        dailyWeatherData[date] = WeatherData(
          dateTime: DateTime.parse(item['dt_txt']),
          temperature: item['main']['temp'].toDouble(),
          weatherCondition: item['weather'][0]['description'],
        );
      }
    }

    _filteredWeatherData = dailyWeatherData.values.toList();
  }

  Future<void> _getMyLocationWeather() async {
    setState(() {
      isLoading = true;
    });

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("Location permission denied by user.");
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        setState(() {
          _currentAddress = placemarks.isNotEmpty
              ? placemarks[0].locality ?? "Unknown Place"
              : "Unknown Place";
        });
        print(
            "latitue : ${position.latitude} longitude : ${position.longitude}");
        await _fetchWeatherData(position.latitude, position.latitude);
      } catch (e) {
        print("Error getting location: $e");
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  _fetchWeatherData(double lat, double long) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await Dio().get(
          'https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${long}&appid=57f2c2f781301d0ba7aa395228631a8e');
      if (response.statusCode == 200) {
        final List<dynamic> weatherList = response.data['list'];
        _processWeatherData(weatherList);
      } else {
        print('API call failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> famousCities = [
    {"name": "Mumbai", "lat": 19.0760, "lon": 72.8777},
    {"name": "Delhi", "lat": 28.6139, "lon": 77.2090},
    {"name": "Bangalore", "lat": 12.9716, "lon": 77.5946},
    {"name": "Chennai", "lat": 13.0827, "lon": 80.2707},
    {"name": "Kolkata", "lat": 22.5726, "lon": 88.3639},
    {"name": "Hyderabad", "lat": 17.3850, "lon": 78.4867},
    {"name": "Pune", "lat": 18.5204, "lon": 73.8567},
    {"name": "Ahmedabad", "lat": 23.0225, "lon": 72.5714},
    {"name": "Jaipur", "lat": 26.9124, "lon": 75.7873},
    {"name": "Lucknow", "lat": 26.8467, "lon": 80.9462},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather Wise'),
        backgroundColor: Colors.cyan.shade200,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(
                    height: 20,
                  ),
                  Text("Fetching weather info")
                ],
              ),
            )
          : Container(
              padding: EdgeInsets.all(10),
              child: Column(
                children: <Widget>[
                  Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                        child: Text(
                          _currentAddress,
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Spacer(),
                      Container(
                        child: IconButton(
                          onPressed: () async {
                            await _getMyLocationWeather();
                          },
                          icon: Icon(
                            Icons.my_location_rounded,
                            size: 40,
                            color: Colors.cyan,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text("Select a City"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: famousCities.map((city) {
                                    return ListTile(
                                      title: Text(city["name"]),
                                      onTap: () {
                                        Navigator.pop(context);
                                        setState(() {
                                          _currentAddress = city["name"];
                                        });
                                        _fetchWeatherData(
                                            city["lat"], city["lon"]);
                                      },
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          );
                        },
                        icon: Icon(
                          Icons.location_on,
                          size: 50,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  _filteredWeatherData.length > 0
                      ? Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16.0),
                              child: ListTile(
                                title: Container(
                                  padding: EdgeInsets.only(bottom: 20),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.thermostat,
                                        size: 50,
                                        color: Colors.blue,
                                      ),
                                      Text(
                                        "${(_filteredWeatherData[0].temperature - 273).toStringAsFixed(1)} °C",
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Icon(
                                      Icons.sunny,
                                      size: 50,
                                      color: Colors.yellow,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      _filteredWeatherData[0].weatherCondition,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: _filteredWeatherData
                                    .sublist(1, 6)
                                    .map((weatherData) => Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${(weatherData.dateTime.day)}/${(weatherData.dateTime.month)}",
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            Text(
                                              "${(weatherData.temperature - 273).toStringAsFixed(1)} °C",
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.15,
                                              child: Text(
                                                weatherData.weatherCondition,
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        )
                      : Container(child: Text("No weather data found"))
                ],
              ),
            ),
    );
  }
}
