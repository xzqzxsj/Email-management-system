from flask import Flask, render_template, request, redirect, url_for, session
import pymysql
from pymysql.cursors import DictCursor

app = Flask(__name__)
app.secret_key = 'your_secret_key_here'  # 用于会话管理

# 数据库配置
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '050327',
    'database': 'emailmanagement',
    'charset': 'utf8mb4',
    'cursorclass': DictCursor
}

def get_db_connection():
    return pymysql.connect(**db_config)


def initialize_database():
    """初始化数据库表结构"""
    conn = get_db_connection()
    try:
        conn = get_db_connection()
        with conn.cursor() as cursor:
            # 创建联系人表
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS contacts (
                uid INT(10) AUTO_INCREMENT PRIMARY KEY NOT NULL,
                uname VARCHAR(25),
                emial VARCHAR(50),
                cellphone BIGINT(11),
                address VARCHAR(100)
            )
            """)

            # 创建电子邮件表
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS emails (
                eid INT(10) AUTO_INCREMENT PRIMARY KEY NOT NULL,
                title VARCHAR(120),
                uid INT(10) UNSIGNED,
                sender_email VARCHAR(50),
                create_time DATETIME,
                reply_eid INT(10),
                textbody TEXT,
                FOREIGN KEY(uid) REFERENCES contacts(uid)
            )
            """)

            # 创建收件人表
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS mail_recipients (
                mid INT(10) PRIMARY KEY AUTO_INCREMENT NOT NULL,
                eid INT(10) NOT NULL,
                uid INT(10) NOT NULL,
                FOREIGN KEY(eid) REFERENCES emails(eid),
                FOREIGN KEY(uid) REFERENCES contacts(uid)
            )
            """)

            # 创建抄送人表
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS copy_recipients (
                cid INT(10) PRIMARY KEY AUTO_INCREMENT NOT NULL,
                eid INT(10) NOT NULL,
                uid INT(10) NOT NULL,
                FOREIGN KEY(eid) REFERENCES emails(eid),
                FOREIGN KEY(uid) REFERENCES contacts(uid)
            )
            """)

            # 创建邮件状态表
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS email_status (
                status_id INT(10) PRIMARY KEY AUTO_INCREMENT NOT NULL,
                eid INT NOT NULL,
                uid INT NOT NULL,
                is_reply BOOLEAN DEFAULT 0,  
                is_deleted BOOLEAN DEFAULT 0, 
                FOREIGN KEY (eid) REFERENCES emails(eid),
                FOREIGN KEY (uid) REFERENCES contacts(uid),
                UNIQUE KEY (eid, uid)
            )
            """)

            # 创建垃圾邮件表
            cursor.execute("""
            CREATE TABLE IF NOT EXISTS junkmails (
                jid INT(10) UNSIGNED PRIMARY KEY AUTO_INCREMENT NOT NULL,
                sender_email VARCHAR(50),
                title VARCHAR(120),
                create_time DATETIME,
                textbody TEXT
            )
            """)
            conn.commit()
    finally:
        conn.close()


# 初始化数据库
# initialize_database()

# 首页路由 - 显示登录页面
@app.route('/')
def index():
    return render_template('login.html')

# 用户登录验证
@app.route('/login', methods=['POST'])
def login():
    email = request.form['email']
    password = request.form['password']
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT uid, uname FROM contacts WHERE email = %s AND password = %s", (email, password))
        user = cursor.fetchone()

        if user:
            session['user_id'] = user['uid']
            session['user_name'] = user['uname']
            return redirect(url_for('dashboard'))
        else:
            return render_template('login.html', error='邮箱或密码错误')
    except Exception as e:
        return render_template('login.html', error=str(e))
    finally:
        cursor.close()
        conn.close()


# 仪表盘 - 显示主要功能
@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session:
        return redirect(url_for('index'))

    return render_template('dashboard.html', user_name=session['user_name'])


# 联系人管理
@app.route('/contacts')
def contacts():
    if 'user_id' not in session:
        return redirect(url_for('index'))

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT uid, uname, email, cellphone, address FROM contacts")
        contacts = cursor.fetchall()
        return render_template('contacts.html', contacts=contacts)
    except Exception as e:
        return render_template('error.html', message=str(e))
    finally:
        cursor.close()
        conn.close()


# 添加联系人
@app.route('/add_contact', methods=['POST'])
def add_contact():
    if 'user_id' not in session:
        return redirect(url_for('index'))

    uname = request.form['uname']
    email = request.form['email']
    cellphone = request.form['cellphone']
    address = request.form['address']
    password = 'default_password'  # 实际应用中应使用哈希密码

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO contacts (uname, email, cellphone, address, password) "
            "VALUES (%s, %s, %s, %s, %s)",
            (uname, email, cellphone, address, password)
        )
        conn.commit()
        return redirect(url_for('contacts'))
    except Exception as e:
        conn.rollback()
        return render_template('error.html', message=str(e))
    finally:
        cursor.close()
        conn.close()


# 邮件列表
@app.route('/emails')
def emails():
    if 'user_id' not in session:
        return redirect(url_for('index'))

    user_id = session['user_id']

    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # 获取收件箱邮件
        cursor.execute("""
            SELECT e.eid, e.title, c.uname AS sender, e.create_time, es.is_reply
            FROM emails e
            JOIN contacts c ON e.uid = c.uid
            JOIN mail_recipients mr ON e.eid = mr.eid
            JOIN email_status es ON e.eid = es.eid AND mr.uid = es.uid
            WHERE mr.uid = %s
            ORDER BY e.create_time DESC
        """, (user_id,))
        inbox_emails = cursor.fetchall()

        # 获取发件箱邮件
        cursor.execute("""
            SELECT e.eid, e.title, e.create_time
            FROM emails e
            WHERE e.uid = %s
            ORDER BY e.create_time DESC
        """, (user_id,))
        sent_emails = cursor.fetchall()

        # 获取垃圾邮件
        cursor.execute("""
            SELECT jid, title, create_time
            FROM junkmails
            ORDER BY create_time DESC
        """)
        junk_emails = cursor.fetchall()

        return render_template('emails.html',
                               inbox_emails=inbox_emails,
                               sent_emails=sent_emails,
                               junk_emails=junk_emails)
    except Exception as e:
        return render_template('error.html', message=str(e))
    finally:
        cursor.close()
        conn.close()


# 发送邮件页面
@app.route('/compose')
def compose():
    if 'user_id' not in session:
        return redirect(url_for('index'))

    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT uid, uname FROM contacts")
        contacts = cursor.fetchall()
        return render_template('compose.html', contacts=contacts)
    except Exception as e:
        return render_template('error.html', message=str(e))
    finally:
        cursor.close()
        conn.close()


# 发送邮件处理
@app.route('/send_email', methods=['POST'])
def send_email():
    if 'user_id' not in session:
        return redirect(url_for('index'))

    user_id = session['user_id']
    title = request.form['title']
    content = request.form['content']
    recipients = request.form.getlist('recipients')
    cc_list = request.form.getlist('cc_list')

    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # 使用存储过程发送邮件
        cursor.callproc('send_email', (
            user_id,
            title,
            content,
            ','.join(map(str, recipients)),
            ','.join(map(str, cc_list))
        ))
        conn.commit()

        return redirect(url_for('emails'))
    except Exception as e:
        conn.rollback()
        return render_template('error.html', message=str(e))
    finally:
        cursor.close()
        conn.close()


# 查看邮件详情
@app.route('/email/<int:email_id>')
def email_detail(email_id):
    if 'user_id' not in session:
        return redirect(url_for('index'))

    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # 获取邮件基本信息
        cursor.execute("""
            SELECT e.*, c.uname AS sender_name
            FROM emails e
            JOIN contacts c ON e.uid = c.uid
            WHERE e.eid = %s
        """, (email_id,))
        email = cursor.fetchone()

        if not email:
            return render_template('error.html', message='邮件不存在')

        # 获取收件人列表
        cursor.execute("""
            SELECT c.uname 
            FROM mail_recipients mr
            JOIN contacts c ON mr.uid = c.uid
            WHERE mr.eid = %s
        """, (email_id,))
        recipients = [r['uname'] for r in cursor.fetchall()]

        # 获取抄送人列表
        cursor.execute("""
            SELECT c.uname 
            FROM copy_recipients cr
            JOIN contacts c ON cr.uid = c.uid
            WHERE cr.eid = %s
        """, (email_id,))
        cc_recipients = [r['uname'] for r in cursor.fetchall()]

        # 标记为已读
        cursor.callproc('mark_as_read', (email_id, session['user_id']))
        conn.commit()

        return render_template('email_detail.html',
                               email=email,
                               recipients=recipients,
                               cc_recipients=cc_recipients)
    except Exception as e:
        return render_template('error.html', message=str(e))
    finally:
        cursor.close()
        conn.close()


# 回复邮件
@app.route('/reply_email/<int:email_id>', methods=['GET', 'POST'])
def reply_email(email_id):
    if 'user_id' not in session:
        return redirect(url_for('index'))

    if request.method == 'GET':
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT title FROM emails WHERE eid = %s", (email_id,))
            original_title = cursor.fetchone()['title']
            return render_template('reply.html',
                                   original_title=original_title,
                                   email_id=email_id)
        except Exception as e:
            return render_template('error.html', message=str(e))
        finally:
            cursor.close()
            conn.close()

    # 处理回复
    content = request.form['content']
    user_id = session['user_id']

    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # 插入回复邮件
        cursor.execute("""
            INSERT INTO emails (title, uid, reply_eid, create_time, textbody)
            VALUES (%s, %s, %s, NOW(), %s)
        """, (f"回复: {request.form['title']}", user_id, email_id, content))
        reply_id = cursor.lastrowid

        # 添加收件人（原邮件发送者）
        cursor.execute("SELECT uid FROM emails WHERE eid = %s", (email_id,))
        original_sender = cursor.fetchone()['uid']
        cursor.execute("""
            INSERT INTO mail_recipients (eid, uid)
            VALUES (%s, %s)
        """, (reply_id, original_sender))

        conn.commit()
        return redirect(url_for('emails'))
    except Exception as e:
        conn.rollback()
        return render_template('error.html', message=str(e))
    finally:
        cursor.close()
        conn.close()

# 退出登录
@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(debug=True,port=5001)