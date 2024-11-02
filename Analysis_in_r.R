#load Data 
q1_2019 <- read_csv("Divvy_Trips_2019_Q1.csv")
q1_2020 <- read_csv("Divvy_Trips_2020_Q1.csv")


#prepare
colnames(q1_2019)
colnames(q1_2020)

#preparing 
(q1_2019 <- rename(q1_2019
                   ,ride_id = trip_id
                   ,rideable_type = bikeid
                   ,started_at = start_time
                   ,ended_at = end_time
                   ,start_station_name = from_station_name
                   ,start_station_id = from_station_id
                   ,end_station_name = to_station_name
                   ,end_station_id = to_station_id
                   ,member_casual = usertype
))



# Inspect the dataframes and look for incongruencies
str(q1_2019)
str(q1_2020)


# Convert ride_id and rideable_type to character so that they can stack correctly
q1_2019 <- mutate(q1_2019, ride_id = as.character(ride_id)
                  ,rideable_type = as.character(rideable_type))
str(q1_2019)



# Stack individual quarter's data frames into one big data frame
all_trips <- bind_rows(q1_2019, q1_2020)



# Remove lat, long, birthyear, and gender fields as this data was dropped beginning in 2020
all_trips <- all_trips %>%
  select(-c(start_lat, start_lng, end_lat, end_lng, birthyear, gender, "tripduration"))





# STEP 3: CLEAN UP AND ADD DATA TO PREPARE FOR ANALYSIS
# Inspect the new table that has been created

colnames(all_trips) #List of column names
nrow(all_trips) #How many rows are in data frame?
dim(all_trips) #Dimensions of the data frame?
head(all_trips) #See the first 6 rows of data frame. Also tail(all_trips)
str(all_trips) #See list of columns and data types (numeric, character, etc)
summary(all_trips) #Statistical summary of data. Mainly for numerics





# Reassign to the desired values (we will go with the current 2020 labels)
all_trips <- all_trips %>%
  mutate(member_casual = recode(member_casual
                                ,"Subscriber" = "member"
                                ,"Customer" = "casual"))

# Check to make sure the proper number of observations were reassigned
table(all_trips$member_casual)




# Add columns that list the date, month, day, and year of each ride
# This will allow us to aggregate ride data for each month, day, or year 
all_trips$date <- as.Date(all_trips$started_at) #The default format is yyyy-mm-dd
all_trips$month <- format(as.Date(all_trips$date), "%m")
all_trips$day <- format(as.Date(all_trips$date), "%d")
all_trips$year <- format(as.Date(all_trips$date), "%Y")
all_trips$day_of_week <- format(as.Date(all_trips$date), "%A")



# Add a "ride_length" calculation to all_trips (in seconds)
all_trips$ride_length <- difftime(all_trips$ended_at,all_trips$started_at)




# Convert "ride_length" from Factor to numeric so we can run calculations on the data
#is.factor(all_trips$ride_length)
all_trips$ride_length <- as.numeric(as.character(all_trips$ride_length))
is.numeric(all_trips$ride_length)




# Remove "bad" data
# The dataframe includes a few hundred entries when bikes were taken out of docks and
#checked for quality by Divvy or ride_length was negative
# We will create a new version of the dataframe (v2) since data is being removed

all_trips_v2 <- all_trips[!(all_trips$start_station_name == "HQ QR" | all_trips$ride_length<0),]







# STEP 4: CONDUCT DESCRIPTIVE ANALYSIS
#=====================================
# Descriptive analysis on ride_length (all figures in seconds)
# Compare members and casual user

# Create a summary table with mean, median, max, and min for each user type
summary_table <- all_trips_v2 %>%
  group_by(member_casual) %>%
  summarise(
    mean_ride_length = mean(ride_length),
    median_ride_length = median(ride_length),
    max_ride_length = max(ride_length),
    min_ride_length = min(ride_length)
  )

# Display the table in a neat format
kable(summary_table, caption = "Summary Statistics of Ride Length by User Type")




# See the average ride time by each day for members vs casual users
aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual + all_trips_v2$day_of_week,
          FUN = mean)



# Notice that the days of the week are out of order. Let's fix that.
all_trips_v2$day_of_week <- ordered(all_trips_v2$day_of_week, 
         levels=c("Sunday", "Monday",
        "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"))







# analyze ridership data by type and weekday & visualize
# Convert started_at to POSIXct format if needed
all_trips_v2$started_at <- as.POSIXct(all_trips_v2$started_at, format = "%Y-%m-%d %H:%M:%S")

all_trips_v2 %>%
  mutate(weekday = wday(started_at, label = TRUE)) %>%  # Create weekday field
  group_by(member_casual, weekday) %>%  # Group by usertype and weekday
  summarise(
    number_of_rides = n(),  # Calculate number of rides
    average_duration = mean(ride_length, na.rm = TRUE)  # Calculate average duration
  ) %>%
  arrange(member_casual, weekday) %>% 
# Let's visualize the number of rides by rider type
  ggplot(aes(x = weekday, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  scale_y_continuous(labels = scales::comma) +  # Format y-axis labels to use commas
  labs(y = "Number of Rides", x = "Weekday", fill = "Rider Type") +  # Add axis labels
  theme_minimal()


ggsave("no of rides each day of week.png", plot = no of rides each day of week, width = 8, height = 6, dpi = 300)






# Let's create a visualization for average duration

all_trips_v2 %>%
mutate(weekday = wday(started_at, label = TRUE)) %>%
  group_by(member_casual, weekday) %>%
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length)) %>%
  arrange(member_casual, weekday) %>%
  ggplot(aes(x = weekday, y = average_duration, fill = member_casual)) +
  geom_col(position = "dodge")





counts <- aggregate(all_trips_v2$ride_length ~ all_trips_v2$member_casual +
                      all_trips_v2$day_of_week, FUN = mean)




