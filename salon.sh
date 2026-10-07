#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --no-psqlrc --quiet --tuples-only --no-align"

sql_escape() {
  local value=$1
  value=${value//\'/\'\'}
  printf '%s' "$value"
}

show_services() {
  echo
  $PSQL -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
}

echo "~~~~~ MY SALON ~~~~~"
echo
echo "Welcome to My Salon, how can I help you?"

show_services

while true; do
  read SERVICE_ID_SELECTED
  if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]; then
    SERVICE_NAME=$($PSQL -c "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
    if [[ -n "$SERVICE_NAME" ]]; then
      break
    fi
  fi
  echo
  echo "I could not find that service. What would you like today?"
  show_services
done

echo
echo "What's your phone number?"
read CUSTOMER_PHONE
ESCAPED_PHONE=$(sql_escape "$CUSTOMER_PHONE")
CUSTOMER_RECORD=$($PSQL -F '|' -c "SELECT customer_id, name FROM customers WHERE phone = '$ESCAPED_PHONE';")

if [[ -z "$CUSTOMER_RECORD" ]]; then
  echo
  echo "I don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
  ESCAPED_NAME=$(sql_escape "$CUSTOMER_NAME")
  CUSTOMER_ID=$($PSQL -c "INSERT INTO customers (phone, name) VALUES ('$ESCAPED_PHONE', '$ESCAPED_NAME') RETURNING customer_id;")
else
  IFS='|' read -r CUSTOMER_ID CUSTOMER_NAME <<< "$CUSTOMER_RECORD"
fi

echo
echo "What time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME
ESCAPED_TIME=$(sql_escape "$SERVICE_TIME")
$PSQL -c "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$ESCAPED_TIME');" > /dev/null

echo
echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."