docker run -p 8000:8000 -p 8001:8001 -d --name kong --link cassandra:cassandra mashape/kong
