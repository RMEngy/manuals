#!/bin/bash

# Получаем процент использования диска
DISK_USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//g')

# Пороговое значение использования диска (75%)
THRESHOLD=75

# Проверяем, превышает ли использование диска пороговое значение
if [ "$DISK_USAGE" -gt "$THRESHOLD" ]; then
  echo "Диск заполнен на ${DISK_USAGE}%, что превышает порог в ${THRESHOLD}%."
  echo "Удаление всех Docker-образов..."

  # Удаляем все Docker-образы
  docker rmi -f $(docker images -q)

  # Проверяем, успешно ли выполнено удаление
  if [ $? -eq 0 ]; then
    echo "Все Docker-образы успешно удалены."
  else
    echo "Не удалось удалить Docker-образы."
  fi
else


###
#!/bin/bash

# Переменные
DOMAIN_1="example1.com"  # Первое доменное имя
DOMAIN_2="example2.com"  # Второе доменное имя
IP_FILE="/tmp/last_ips.txt"  # Файл для хранения последних IP-адресов

# Функция для получения текущих IP-адресов
get_current_ips() {
    local domain=$1
    nslookup $domain | grep "Address" | awk '{print $2}' | sort
}

# Функция для получения последних IP-адресов из файла
get_last_ips() {
    local domain=$1
    grep "$domain" $IP_FILE | awk '{print $2}' | sort
}

# Функция для сохранения текущих IP-адресов в файл
save_current_ips() {
    echo "$DOMAIN_1 $(get_current_ips $DOMAIN_1)" > $IP_FILE
    echo "$DOMAIN_2 $(get_current_ips $DOMAIN_2)" >> $IP_FILE
}

# Основной код

# Если файл с последними IP-адресами не существует, создаем его
if [[ ! -f $IP_FILE ]]; then
    save_current_ips
    echo "Initial IPs saved. Run the script again to check for changes."
    exit 0
fi

# Получаем текущие IP-адреса
CURRENT_IP_1=$(get_current_ips $DOMAIN_1)
CURRENT_IP_2=$(get_current_ips $DOMAIN_2)

# Получаем последние IP-адреса из файла
LAST_IP_1=$(get_last_ips $DOMAIN_1)
LAST_IP_2=$(get_last_ips $DOMAIN_2)

# Сравниваем IP-адреса
if [[ "$CURRENT_IP_1" != "$LAST_IP_1" || "$CURRENT_IP_2" != "$LAST_IP_2" ]]; then
    echo "OK"  # Выводим OK, если IP-адреса изменились
    save_current_ips  # Сохраняем новые IP-адреса
else
    echo "NO CHANGE"  # Выводим, если изменений нет
fi
  echo "Использование диска (${DISK_USAGE}%) в пределах нормы. Никаких действий не требуется."
fi
