DROP DATABASE IF EXISTS EmailManagement;
CREATE DATABASE EmailManagement CHARSET=UTF8;
USE EmailManagement;

# 创建联系人表
DROP TABLE IF EXISTS contacts;
CREATE TABLE contacts(
uid INT(10) UNSIGNED PRIMARY KEY AUTO_INCREMENT NOT NULL,
uname VARCHAR(25),
email VARCHAR(50),
cellphone BIGINT(11),
address VARCHAR(100),
password VARCHAR(100)
);
# 添加check约束
ALTER TABLE contacts ADD CHECK (cellphone>0);

# 创建电子邮件表
DROP TABLE IF EXISTS emails;
CREATE TABLE emails(
eid INT(10) UNSIGNED PRIMARY KEY AUTO_INCREMENT NOT NULL,
title VARCHAR(120),
uid INT(10) UNSIGNED,   # 发件人编号
sender_email VARCHAR(50),  # 发件人邮箱
create_time DATETIME,
reply_eid INT(10),
textbody TEXT,
FOREIGN KEY(uid) REFERENCES contacts(uid)
);

# 创建收件人集合表
DROP TABLE IF EXISTS mail_recipients;
CREATE TABLE mail_recipients(
mid INT(10) UNSIGNED PRIMARY KEY AUTO_INCREMENT NOT NULL,
eid INT(10) UNSIGNED NOT NULL,
uid INT(10) UNSIGNED NOT NULL,
FOREIGN KEY(eid) REFERENCES emails(eid),
FOREIGN KEY(uid) REFERENCES contacts(uid)
);

# 创建抄送人集合表
DROP TABLE IF EXISTS copy_recipients;
CREATE TABLE copy_recipients(
cid INT(10) UNSIGNED PRIMARY KEY AUTO_INCREMENT NOT NULL,
eid INT(10) UNSIGNED NOT NULL,
uid INT(10) UNSIGNED NOT NULL,
FOREIGN KEY(eid) REFERENCES emails(eid),
FOREIGN KEY(uid) REFERENCES contacts(uid)
);

# 创建邮件状态表
DROP TABLE IF EXISTS email_status;
CREATE TABLE email_status (
status_id INT(10) UNSIGNED PRIMARY KEY AUTO_INCREMENT NOT NULL,
eid INT UNSIGNED NOT NULL,
uid INT UNSIGNED NOT NULL,
is_reply BOOLEAN DEFAULT 0,   # 是否回复,默认0（没回复）
is_deleted BOOLEAN DEFAULT 0,  # 是否删除，默认0（没删除）
FOREIGN KEY (eid) REFERENCES emails(eid),
FOREIGN KEY (uid) REFERENCES contacts(uid),
UNIQUE KEY (eid, uid)
);

# 创建垃圾邮件表
DROP TABLE IF EXISTS junkmails;
CREATE TABLE junkmails(
jid INT(10) UNSIGNED PRIMARY KEY AUTO_INCREMENT NOT NULL,
sender_email VARCHAR(50),
title VARCHAR(120),
create_time DATETIME,
textbody TEXT
);


# 插入数据
# 插入联系人数据
ALTER TABLE contacts AUTO_INCREMENT=1;
INSERT INTO contacts (uname, email, cellphone, address,password) VALUES
('冯二', 'abc123@company.com', 13288886666, '北京市海淀区雪花大道博信国际大厦1楼101','23760182Tx'),
('张三', 'zhangsan@company.com', 13912345678, '上海市浦东新区科技园88号','zS23412345$'),
('李四', 'lisi@company.com', 13787654321, '广州市天河区软件园A栋','lslS123dr45**'),
('王五', 'wangwu@company.com', 13511223344, '上海市浦东新区科技园88号','www1234098'),
('赵六', 'zhaoliu@company.com', 13655443322, '上海市浦东新区科技园88号','12235012');
delete from contacts;
select * from contacts;

ALTER TABLE emails AUTO_INCREMENT=1;
# 插入邮件数据
INSERT INTO emails (title,uid,sender_email,create_time,textbody) VALUES
('项目会议通知',1,'abc123@company.com','2024-05-17 16:20:45','今晚7点紧急召开项目进度会议'),
('需求文档反馈',2,'zhangsan@company.com','2024-05-18 15:10:32','请查阅附件中的需求文档并提供修改意见'),
('系统升级计划',3,'lisi@company.com','2024-06-12 11:30:27','本周末将进行系统维护升级');

# 插入回复邮件(在插入原始邮件之后)
INSERT INTO emails (title,uid,sender_email,reply_eid,create_time,textbody) VALUES
('回复：项目会议通知',2,'zhangsan@company.com',1,'2024-05-17 16:40:23','收到'),
('回复：项目会议通知',3,'lisi@company.com',1,'2024-05-17 18:10:10','收到'),
('回复：需求文档反馈',1,'abc123@company.com',2,'2024-05-18 16:10:11','已审阅，建议增加用户管理模块'),
('回复：系统升级计划',4,'wangwu@company.com',3,'2024-06-12 13:20:45','升级期间服务是否中断'),
('回复：系统升级计划',5,'zhaoliu@company.com',3,'2024-06-12 12:50:05','已知');
delete from emails;
select * from emails;

ALTER TABLE mail_recipients AUTO_INCREMENT=1;
# 插入收件人数据
INSERT INTO mail_recipients (eid,uid) VALUES
(1,2),(1,3),(1,4),    # 邮件1的收件人
(2,1),(2,3),          # 邮件2的收件人
(3,1),(3,4),(3,5),    # 邮件3的收件人
# 插入回复邮件的收件人数据
(4,1),      # 邮件4的收件人
(5,1),     # 邮件5的收件人
(6,2),     # 邮件6的收件人
(7,3),     # 邮件7的收件人
(8,3);     # 邮件8的收件人
delete from mail_recipients;
select * from mail_recipients;

ALTER TABLE copy_recipients AUTO_INCREMENT=1;
# 插入抄送人数据
INSERT INTO copy_recipients (eid,uid) VALUES
(1,5),                  # 邮件1抄送
(2,4), (2,5),          # 邮件2抄送
(3,2);                  # 邮件3抄送
delete from copy_recipients;
select * from copy_recipients;

ALTER TABLE email_status AUTO_INCREMENT=1;
# 插入邮件状态数据
INSERT INTO email_status (eid,uid,is_reply) VALUES
(1,2,1),  # 张三已读邮件1
(1,3,1),  # 李四未读邮件1
(1,4,0),  # 王五未读邮件1
(2,1,1),  # 冯二已读邮件2
(2,3,0),  # 李四未读邮件2
(3,1,0),  # 冯二未读邮件3
(3,4,1),  # 王五已读邮件3
(3,5,1);  # 赵六已读邮件3
delete from email_status;
select*from email_status;

# 修改信息
# 修改联系人表：增加最近一次登录时间字段
ALTER TABLE contacts ADD COLUMN last_login DATETIME;
select * from contacts;

# 通过标题或者文本关键词自动标记重要邮件
UPDATE emails 
SET title=CONCAT('[重要邮件!!!]',title)
WHERE (title LIKE '%紧急%' OR title LIKE '%重要%' OR textbody LIKE '%紧急%' OR textbody LIKE '%截止%');
select * from emails;

# 删除信息
# 定期清理超过1年的抄送邮件
DELETE FROM copy_recipients
WHERE create_time < DATE_SUB(NOW(),INTERVAL 1 YEAR);

# 定期删除超过2个月的垃圾邮件
DELETE FROM junkmails 
WHERE create_time < DATE_SUB(NOW(),INTERVAL 2 MONTH);

# 数据查询
# 查询联系人中姓"赵"的人
SELECT * FROM contacts WHERE uname LIKE '赵%';

# 查询回复过邮件的人及回复数量,显示用户编号id、姓名、和回复邮件的数量
SELECT c.uid AS 用户编号,c.uname AS 姓名,COUNT(DISTINCT e.eid) AS 回复邮件数量
FROM contacts c
JOIN emails e ON c.uid=e.uid
WHERE e.reply_eid IS NOT NULL
GROUP BY c.uid,c.uname;

# 查询抄送人数量≥2的邮件,显示邮件id、邮件主题、邮件内容
SELECT e.eid AS 邮件ID,e.title AS 邮件主题,e.textbody AS 邮件内容
FROM emails e
WHERE e.eid IN (SELECT eid FROM copy_recipients GROUP BY eid HAVING COUNT(*)>=2);

# 查询被回复过邮件的回复耗时,显示发件人姓名、原始邮件主题、回复人ID、回复耗时（分钟）
SELECT c.uname AS 发件人,e1.title AS 原始邮件主题,e2.uid AS 回复人ID,
timestampdiff(MINUTE,e1.create_time,e2.create_time) AS 回复耗时（分钟）
FROM emails e1 JOIN emails e2 ON e1.eid=e2.reply_eid 
JOIN contacts c ON e1.uid=c.uid;   # e1是发件，e2是收件

# 查询用户收发邮件数据量,显示用户ID、用户姓名、发件数量（相同的邮件发给不同人算一封）、收件数量
SELECT c.uid AS 用户ID,c.uname AS 用户姓名,COUNT(DISTINCT m.eid) AS 收件数量,
COUNT(DISTINCT e.eid) AS 发件数量
FROM contacts c LEFT JOIN mail_recipients m ON c.uid=m.uid 
LEFT JOIN emails e ON c.uid=e.uid
GROUP BY c.uid, c.uname;

# 添加视图
# 创建视图显示用户未回复的邮件数量
drop view if exists no_reply_email;
CREATE VIEW no_reply_email AS
SELECT c.uid AS 用户ID,c.uname AS 用户姓名,count(es.eid) AS 未回复邮件数量
from contacts c left JOIN (select * from email_status where is_reply=0) es on c.uid=es.uid
group by c.uid,c.uname
order by count(es.eid) DESC;
select * from no_reply_email;

# 创建弱密码用户视图
drop view if exists weak_password_users;
CREATE VIEW weak_password_users AS
SELECT uid,uname,email
FROM contacts
WHERE uid not in 
(select uid from contacts where password REGEXP '[0-9]' and
password REGEXP '[a-z]' and
password REGEXP '[A-Z]' and 
password REGEXP '[^a-z0-9]');
select * from weak_password_users;


# 存储过程
# 对已回复邮件进行状态标记
DELIMITER //
CREATE PROCEDURE mark_as_read(IN mail_id INT,IN user_uid INT)
BEGIN
    UPDATE email_status
    SET is_reply=1
    WHERE uid=user_uid and eid=mail_id;
END //
DELIMITER ;

# 对已删除邮件进行标记
DELIMITER //
CREATE PROCEDURE mark_as_deleted(IN mail_id INT,IN user_uid INT)
BEGIN
    UPDATE email_status
    SET is_deleted=1
    WHERE uid=user_uid and eid=mail_id;
END //
DELIMITER ;

# 员工发邮件存储过程+事务
drop procedure send_email;
DELIMITER //
CREATE PROCEDURE send_email(IN s_name VARCHAR(25),IN e_title VARCHAR(120),IN content TEXT,IN r_email VARCHAR(50),IN c_list TEXT)
BEGIN
    DECLARE email_id INT;            # 记录邮件编号
    DECLARE c_pos INT DEFAULT 1;     # 记录搜索位置
    DECLARE r_id INT;                # 记录收件人编号
    DECLARE c_email VARCHAR(50);     # 记录抄送人邮箱
    DECLARE c_id INT;                # 记录抄送人编号
    
    START TRANSACTION;
	# 验证收件人是否在公司
	IF NOT EXISTS (SELECT 1 FROM contacts WHERE email=r_email) THEN
		SELECT '收件人不存在';
        ROLLBACK;
	ELSE
        SELECT uid INTO r_id FROM contacts WHERE email =r_email; # 获取收件人编号
        # 插入邮箱
		INSERT INTO emails (title,uid,textbody,create_time) VALUES (e_title,s_id,content,NOW());
        # 获取邮件编号
		select eid into email_id from emails where title=e_title and uid=s_id and textbody=content;  
        # 插入收件集合
        INSERT INTO mail_recipients (eid,uid) VALUES (email_id,recipient);
	END IF;
	# 验证抄送人是否在公司
	WHILE c_pos<=LENGTH(cc_list) and c_list <> '' DO
		SET c_email=SUBSTRING_INDEX(SUBSTRING_INDEX(c_list,',',c_pos),',',-1);  # 假设分隔符为逗号
		IF NOT EXISTS (SELECT 1 FROM contacts WHERE email=c_email) THEN
			SELECT '抄送人不存在';
		ELSE 
			SELECT uid INTO c_id FROM contacts WHERE email=c_email;  # 获取抄送人编号
			INSERT INTO copy_recipients (eid,uid) VALUES (email_id,c_id);  # 插入查送人表
        END IF;
        SET c_pos=c_pos+1;
	END WHILE;
    COMMIT;
END //
DELIMITER ;

# 添加联系人：该员工需要添加来自外部公司的联系人
drop procedure add_new_contacts;
DELIMITER //
CREATE PROCEDURE add_new_contacts(IN s_name VARCHAR(25),IN s_email VARCHAR(50),IN s_phone BIGINT(11),IN s_address VARCHAR(100))
BEGIN
	IF NOT EXISTS (SELECT 1 FROM contacts WHERE email=s_email) THEN
		INSERT INTO contacts(uname,email,cellphone,address)
        VALUES (s_name,s_email,s_phone,s_address);
	ELSE
		SELECT '联系人已存在';
	END IF;	
END //
DELIMITER ;

# 触发器
# 函数判断是否为垃圾邮件
drop function is_junkmail;
DELIMITER //
CREATE FUNCTION is_junkmail(s_email VARCHAR(50),title VARCHAR(120),textbody TEXT) 
RETURNS BOOLEAN
BEGIN
    DECLARE junkmail_score INT DEFAULT 0;
    # 标题含广告关键词
    IF title REGEXP '促销|折扣|限时|优惠|点击|http[s]?://' THEN
        SET junkmail_score=junkmail_score+1;
    END IF;
    
    # 正文含链接
    IF textbody REGEXP 'http[s]?://|www\\.[a-z0-9]+\\.[a-z]+' THEN
        SET junkmail_score=junkmail_score+1;
    END IF;
    
    # 正文短且含电话号码
    IF CHAR_LENGTH(textbody)<50 AND textbody REGEXP '1[3-9][0-9]{9}|[0-9]{3,4}-[0-9]{7,8}' THEN
        SET junkmail_score=junkmail_score+1;
    END IF;
    
    # 发件人不在邮件系统内
    IF s_email not in (select email from contacts) THEN
		SET junkmail_score=junkmail_score+1;
	END IF;
    RETURN junkmail_score>=3; # 满足3个条件判定为垃圾邮件
END //
DELIMITER ;

show variables like 'log_bin_trust_function_creators';
set global log_bin_trust_function_creators=1;


# 触发器+垃圾邮件
drop trigger mark_junkmail;
DELIMITER //
CREATE TRIGGER mark_junkmail
AFTER INSERT ON emails  # 触发时间为插入邮件表之后
FOR EACH ROW
BEGIN
	DECLARE s_email VARCHAR(50);
	SELECT sender_email INTO s_email FROM emails WHERE create_time=NEW.create_time;  # 先提取出发件人的邮箱
    IF is_junkmail(s_email,NEW.title,NEW.textbody) THEN
        INSERT INTO junkmails(sender_email,title,create_time,textbody) VALUES
        (s_email,NEW.title,NEW.create_time,NEW.textbody);
         
         # 从正常的邮件表里删除垃圾邮件
         DELETE FROM email WHERE create_time=NEW.create_time;
    END IF;
END //
DELIMITER ;

# 移除被误判的邮件
drop procedure remove_junkmail;
DELIMITER //
CREATE PROCEDURE remove_junkmail(IN mail_jid INT)
BEGIN
    declare sm VARCHAR(50);   # 邮箱
    declare st VARCHAR(100);  # 标题
    declare sc DATETIME;      # 时间
    declare content TEXT;     # 内容
    declare s_id INT;         # 编号
    # 提取要移除的邮件信息
    SELECT sender_email,title,create_time,textbody into sm,st,sc,content
    from junkmails where jid=mail_jid;
    
	# 如果发件人不在系统中，加入系统
    IF sm not in (select email from contacts) THEN
		INSERT INTO contacts(email) VALUES (sm);
	END IF;
    
    # 获取发件人的编号
    select uid into s_id from contacts where email=sm;
    
    # 将邮件重新插入正常邮件箱
	INSERT into emails(title,uid,sender_email,create_time,textbody)
    VALUES(st,s_id,sm,sc,content);
    
    # 从垃圾箱中删除
    delete from junkmail where jid=mail_jid;   
END //
DELIMITER ;































