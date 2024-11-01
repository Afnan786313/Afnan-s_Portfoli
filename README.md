# Data Analytics Capstone Project
**Author:** Afnan Ali Mehsud  
**Role:** Junior Data Analyst  

## Background

This project is part of the Google Data Analytics Certification capstone project. As a junior data analyst working within the marketing analytics team at **Cyclistic**, a bike-share company in Chicago, I am tasked with analyzing customer usage patterns.

The **director of marketing** believes that Cyclistic’s future success relies on increasing the number of annual memberships. Therefore, my team aims to understand how **casual riders** and **annual members** use Cyclistic bikes differently. By leveraging these insights, the team will develop a targeted marketing strategy aimed at converting casual riders into annual members. Before any recommendations can be implemented, however, they must receive approval from Cyclistic executives, backed by compelling data insights and professional data visualizations.

## Project Overview

This case study will guide you through the **data analysis process** using Cyclistic's bike-share data. Throughout the project, you will follow these steps:
1. **Ask** - Define the business task and identify key questions.
2. **Prepare** - Collect, clean, and organize the data.
3. **Process** - Conduct thorough data cleaning and verification.
4. **Analyze** - Explore the data, look for trends, and identify insights.
5. **Share** - Present findings in a clear and concise way.
6. **Act** - Make recommendations based on insights derived from the analysis.

## Case Study Roadmap

The project includes a series of **guiding questions** and **key tasks** for each stage of the process. These checkpoints will help you stay on track and ensure that each step is addressed thoroughly.

## Goal

The goal of this case study is to perform data-driven analysis to support Cyclistic’s business objectives, utilizing bike-share data to answer strategic questions that will inform decision-making.

# Lets prepare the data

## Step 2: Wrangle Data and Combine into a Single File

1. **Compare Column Names in Each File:**
    - We need to ensure column names match perfectly across files before merging.

    ```r
    colnames(q1_2019)
    colnames(q1_2020)
    ```

2. **Rename Columns in `q1_2019` to Match `q1_2020`:**
    - Renaming columns in `q1_2019` to ensure consistency.

    ```r
    q1_2019 <- rename(q1_2019,
                      ride_id = trip_id,
                      rideable_type = bikeid,
                      started_at = start_time,
                      ended_at = end_time,
                      start_station_name = from_station_name,
                      start_station_id = from_station_id,
                      end_station_name = to_station_name,
                      end_station_id = to_station_id,
                      member_casual = usertype)
    ```

3. **Inspect Dataframes for Inconsistencies:**

    ```r
    str(q1_2019)
    str(q1_2020)
    ```

4. **Convert Columns to Character Type:**
    - Convert `ride_id` and `rideable_type` to character so they stack correctly.

    ```r
    q1_2019 <- mutate(q1_2019,
                      ride_id = as.character(ride_id),
                      rideable_type = as.character(rideable_type))
    ```

5. **Stack Dataframes Together and Drop Unneeded Columns:**

    ```r
    all_trips <- bind_rows(q1_2019, q1_2020)
    all_trips <- all_trips %>% select(-c(start_lat, start_lng, end_lat, end_lng, birthyear, gender, "tripduration"))
    ```

---

## Step 3: Clean Up and Add Data to Prepare for Analysis

1. **Inspect the Combined Dataframe:**

    ```r
    colnames(all_trips)
    nrow(all_trips)
    dim(all_trips)
    head(all_trips)
    str(all_trips)
    summary(all_trips)
    ```

2. **Standardize `member_casual` Column:**
    - Replace older labels with standardized labels.

    ```r
    table(all_trips$member_casual)
    all_trips <- all_trips %>%
        mutate(member_casual = recode(member_casual, "Subscriber" = "member", "Customer" = "casual"))
    table(all_trips$member_casual)
    ```

3. **Add Date-Based Columns for Aggregation:**

    ```r
    all_trips$date <- as.Date(all_trips$started_at)
    all_trips$month <- format(as.Date(all_trips$date), "%m")
    all_trips$day <- format(as.Date(all_trips$date), "%d")
    all_trips$year <- format(as.Date(all_trips$date), "%Y")
    all_trips$day_of_week <- format(as.Date(all_trips$date), "%A")
    ```

4. **Add `ride_length` Column:**
    - Calculate the ride duration for consistency.

    ```r
    all_trips$ride_length <- difftime(all_trips$ended_at, all_trips$started_at)
    ```

5. **Convert `ride_length` to Numeric and Remove Bad Data:**

    ```r
    all_trips$ride_length <- as.numeric(as.character(all_trips$ride_length))
    all_trips_v2 <- all_trips[!(all_trips$start_station_name == "HQ QR" | all_trips$ride_length < 0),]
    ```

---

## Step 4: Conduct Descriptive Analysis
1. **Analyze `ride_length`:**
    - Calculate basic statistics.

    ```r
    mean(all_trips_v2$ride_length)
    median(all_trips_v2$ride_length)
    max(all_trips_v2$ride_length)
    min(all_trips_v2$ride_length)
    summary(all_trips_v2$ride_length)
    ```

2. **Compare Ride Length by Rider Type:**

    ```r
    aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = mean)
    aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = median)
    aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = max)
    aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual, FUN = min)
    ```

    

3. **Visualize Number of Rides by Day and Rider Type:**
```r
# Create a summarized dataframe for the number of rides
number_of_rides_data <- all_trips_v2 %>%
    mutate(weekday = wday(started_at, label = TRUE)) %>%
    group_by(member_casual, weekday) %>%
    summarise(
        number_of_rides = n(),
        average_duration = mean(ride_length),
        .groups = "drop"  # Drop groups after summarizing
    ) %>%
    arrange(member_casual, weekday)

# Plot the number of rides
ggplot(number_of_rides_data, aes(x = weekday, y = number_of_rides, fill = member_casual)) +
    geom_col(position = "dodge") +
    labs(title = "Number of Rides by Day and Rider Type",
         x = "Day of the Week",
         y = "Number of Rides") +
    theme_minimal()

```
 ![Number of Rides by Day and Rider Type](no of rides each day of week.png)

