# code-server-installer


روش استاندارد
adduser myuser

exit

ssh myuser@YOUR_SERVER_IP

curl -sSL https://raw.githubusercontent.com/Pezhman5252/code-server-installer/main/install.sh | sudo bash




راهنمای مدیریت سرویس Code-Server

cd /opt/code-server


مشاهده لاگ هر دو سرویس:
docker compose logs -f

مشاهده لاگ فقط سرویس code-server:
docker compose logs -f code-server

مشاهده لاگ فقط سرویس nginx-proxy:
docker compose logs -f nginx-proxy



| عملیات | دستور |
| :--- | :--- |
| **بررسی وضعیت** | `docker compose ps` |
| **متوقف کردن** | `docker compose down` |
| **شروع کردن** | `docker compose up -d` |
| **ری‌استارت کردن** | `docker compose restart` |
| **آپدیت کردن** | `docker compose pull && docker compose up -d --build` |
| **مشاهده لاگ‌ها** | `docker compose logs -f` |

