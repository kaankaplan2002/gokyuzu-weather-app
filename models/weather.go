package models

import "time"

// WeatherData represents the structured weather response we send to the frontend
type WeatherData struct {
	CityName            string    `json:"city_name"`
	Country             string    `json:"country"`
	Latitude            float64   `json:"latitude"`
	Longitude           float64   `json:"longitude"`
	Temperature         float64   `json:"temperature"`
	RelativeHumidity    int       `json:"relative_humidity"`
	ApparentTemperature float64   `json:"apparent_temperature"`
	Precipitation       float64   `json:"precipitation"`
	WeatherCode         int       `json:"weather_code"`
	WeatherDescription  string    `json:"weather_description"`
	WindSpeed           float64   `json:"wind_speed"`
	Time                string    `json:"time"`
	FetchedAt           time.Time `json:"fetched_at"`
}

// FavoriteCity represents a user's favorited city
type FavoriteCity struct {
	ID        string    `json:"id"`
	CityName  string    `json:"city_name"`
	Country   string    `json:"country"`
	Latitude  float64   `json:"latitude"`
	Longitude float64   `json:"longitude"`
	AddedAt   time.Time `json:"added_at"`
}

// SearchHistory represents an entry in the search logs
type SearchHistory struct {
	ID          string    `json:"id"`
	CityName    string    `json:"city_name"`
	Country     string    `json:"country"`
	Temperature float64   `json:"temperature"`
	WeatherCode int       `json:"weather_code"`
	SearchTime  time.Time `json:"search_time"`
}
