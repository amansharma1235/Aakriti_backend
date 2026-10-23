-- Aakriti Ultrasound & Diagnostic Clinic Complete Database Dump
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `admin_users`;
CREATE TABLE `admin_users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password` varchar(255) NOT NULL,
  `status` varchar(20) DEFAULT 'Active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `admin_users` (`id`, `name`, `email`, `password`, `status`, `created_at`) VALUES
(1, 'Aman Sharma', 'admin@aakriti.com', '809056', 'Active', '2026-09-22 14:37:21');

DROP TABLE IF EXISTS `patients`;
CREATE TABLE `patients` (
  `id` int NOT NULL AUTO_INCREMENT,
  `patient_id` varchar(20) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `mobile` varchar(15) NOT NULL,
  `age` int DEFAULT NULL,
  `gender` varchar(20) DEFAULT NULL,
  `blood_group` varchar(10) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `address` text,
  `status` varchar(20) DEFAULT 'Active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `patient_id` (`patient_id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `patients` (`id`, `patient_id`, `full_name`, `mobile`, `age`, `gender`, `blood_group`, `email`, `address`, `status`, `created_at`) VALUES
(1, 'AKR001', 'Rahul Kumar', '9876543210', 28, 'Male', 'O+', 'rahul@gmail.com', 'lucknow', 'Active', '2026-09-18 23:22:19'),
(2, 'AKR131', 'aman sharma', '9519701963', 21, 'Male', 'A+', 'amansharma274502@gmail.com', 'lar', 'Active', '2026-09-19 00:32:02'),
(3, 'AKR132', 'ankit kumar', '8957878861', 20, 'Male', 'B-', 'ankit23@gmail.com', 'deoria', 'Active', '2026-09-19 00:38:25'),
(4, 'AKR133', 'rohan', '9519701963', 42, 'Male', 'A+', 'rohan@gmail.com', 'basti', 'Active', '2026-09-19 00:41:05'),
(5, 'AKR139', 'Dr. Verification Test', '', 32, 'Female', 'A+', NULL, NULL, 'Active', '2026-09-23 07:41:51'),
(6, 'AKR140', 'Test', '', 30, 'Male', 'A+', NULL, NULL, 'Active', '2026-09-23 07:42:04'),
(7, 'AKR141', 'Dr. Verification Test', '', 32, 'Female', 'A+', NULL, NULL, 'Active', '2026-09-23 07:42:45'),
(8, 'AKR142', 'Dr. Verification Test', '', 32, 'Female', 'A+', NULL, NULL, 'Active', '2026-09-23 07:42:55'),
(9, 'AKR143', 'Dr. Verification Test', '', 32, 'Female', 'A+', NULL, NULL, 'Active', '2026-09-23 07:43:06'),
(10, 'PT4ZM95N', 'amansharma274502', '', NULL, 'Male', 'A+', 'amansharma274502@gmail.com', NULL, 'Active', '2026-09-24 12:15:35');

DROP TABLE IF EXISTS `doctors`;
CREATE TABLE `doctors` (
  `id` int NOT NULL AUTO_INCREMENT,
  `doctor_id` varchar(20) NOT NULL,
  `doctor_name` varchar(100) NOT NULL,
  `specialization` varchar(100) DEFAULT NULL,
  `mobile` varchar(15) DEFAULT NULL,
  `experience` varchar(50) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'Active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `doctor_id` (`doctor_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `doctors` (`id`, `doctor_id`, `doctor_name`, `specialization`, `mobile`, `experience`, `status`, `created_at`) VALUES
(1, 'DOC001', 'Dr. Rajesh Sharma', 'Radiologist', '9876543210', '12 Years', 'Active', '2026-09-19 12:00:08'),
(2, 'DOC002', 'Dr. Neha Verma', 'Sonologist', '9123456780', '8 Years', 'Active', '2026-09-19 12:00:08'),
(3, 'DOC003', 'Dr. Amit Gupta', 'Radiologist', '9988776655', '10 Years', 'Active', '2026-09-19 12:00:08'),
(4, 'DOC004', 'Dr. Priya Singh', 'Pathologist', '9876501234', '6 Years', 'Active', '2026-09-19 12:00:08'),
(5, 'DOC005', 'Dr. Ankit Verma', 'Physician', '9001122334', '5 Years', 'Active', '2026-09-19 12:00:08');

DROP TABLE IF EXISTS `services`;
CREATE TABLE `services` (
  `id` int NOT NULL AUTO_INCREMENT,
  `service_id` varchar(20) NOT NULL,
  `service_name` varchar(100) NOT NULL,
  `category` varchar(100) DEFAULT NULL,
  `price` decimal(10,2) NOT NULL,
  `duration` varchar(50) DEFAULT NULL,
  `description` text,
  `status` varchar(20) DEFAULT 'Active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `service_id` (`service_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `services` (`id`, `service_id`, `service_name`, `category`, `price`, `duration`, `description`, `status`, `created_at`) VALUES
(1, 'SRV001', 'Ultrasound Whole Abdomen', 'Ultrasound', '800.00', '30 min', 'Comprehensive abdominal scan', 'Active', '2026-09-19 12:00:08'),
(2, 'SRV002', 'Pelvic & Obstetric Ultrasound', 'Ultrasound', '1000.00', '25 min', 'Pelvic & fetal growth evaluation', 'Active', '2026-09-19 12:00:08'),
(3, 'SRV003', 'Thyroid & Neck Doppler', 'Doppler', '1200.00', '20 min', 'Color Doppler scan for thyroid vascularity', 'Active', '2026-09-19 12:00:08'),
(4, 'SRV004', 'KUB & Prostate Ultrasound', 'Ultrasound', '750.00', '20 min', 'Kidneys, ureters and bladder scan', 'Active', '2026-09-19 12:00:08'),
(5, 'SRV005', 'Complete Blood Count (CBC)', 'Pathology', '350.00', '15 min', 'Routine blood profile test', 'Active', '2026-09-19 12:00:08'),
(6, 'SRV006', 'Liver Function Test (LFT)', 'Pathology', '600.00', '20 min', 'Bilirubin and liver enzyme evaluation', 'Active', '2026-09-19 12:00:08'),
(7, 'SRV007', 'Thyroid Profile (T3, T4, TSH)', 'Pathology', '450.00', '15 min', 'Thyroid hormone level testing', 'Active', '2026-09-19 12:00:08'),
(8, 'SRV008', 'Fasting Blood Sugar (FBS)', 'Pathology', '150.00', '10 min', 'Glucose level check', 'Active', '2026-09-19 12:00:08');

DROP TABLE IF EXISTS `appointments`;
CREATE TABLE `appointments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `appointment_id` varchar(20) NOT NULL,
  `patient_id` varchar(20) NOT NULL,
  `patient_name` varchar(100) NOT NULL,
  `mobile` varchar(15) DEFAULT NULL,
  `service_name` varchar(100) NOT NULL,
  `appointment_date` date NOT NULL,
  `appointment_time` varchar(20) DEFAULT NULL,
  `doctor_name` varchar(100) DEFAULT NULL,
  `note` text,
  `status` varchar(20) DEFAULT 'Pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `appointment_id` (`appointment_id`),
  KEY `patient_id` (`patient_id`),
  CONSTRAINT `appointments_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `appointments` (`id`, `appointment_id`, `patient_id`, `patient_name`, `mobile`, `service_name`, `appointment_date`, `appointment_time`, `doctor_name`, `note`, `status`, `created_at`) VALUES
(1, 'APT1001', 'AKR001', 'Rahul Kumar', '9876543210', 'Ultrasound Whole Abdomen', '2026-09-19', '10:30 AM', 'Dr. Rajesh Sharma', 'Fasting 6 hours mandatory', 'Confirmed', '2026-09-19 12:00:08'),
(2, 'APT1002', 'AKR131', 'Aman Sharma', '9519701963', 'Pelvic & Obstetric Ultrasound', '2026-09-19', '11:15 AM', 'Dr. Neha Verma', 'Routine diagnostic follow-up', 'Confirmed', '2026-09-19 12:00:08'),
(3, 'APT1003', 'AKR001', 'Priya Singh', '9811122334', 'Thyroid & Neck Doppler', '2026-09-19', '12:00 PM', 'Dr. Rajesh Sharma', 'Previous report brought along', 'Pending', '2026-09-19 12:00:08'),
(4, 'APT1004', 'AKR001', 'Amit Verma', '9955588776', 'KUB & Prostate Ultrasound', '2026-09-19', '01:30 PM', 'Dr. Amit Gupta', 'Full bladder required', 'Pending', '2026-09-19 12:00:08'),
(5, 'APT1005', 'AKR001', 'Ravi Gupta', '9899911223', 'Complete Blood Count (CBC)', '2026-09-19', '04:00 PM', 'Dr. Priya Singh', 'Sample collected', 'Completed', '2026-09-19 12:00:08'),
(6, 'TEST999', 'AKR131', 'Aman Sharma', '9876543210', 'Ultrasound Scan', '2026-09-22', '10:30 AM', '', 'Test appointment', 'Completed', '2026-09-22 13:18:36'),
(7, 'APT-1790063830181', 'AKR131', 'Aman Sharma', '8957878861', 'Ultrasound Scan', '2026-09-24', '4:27 PM', '', '', 'Cancelled', '2026-09-22 13:27:10'),
(8, 'APT-1790063876568', 'AKR131', 'nandani', '7800839003', 'Ultrasound Scan', '2026-09-23', '3:27 PM', '', '', 'Confirmed', '2026-09-22 13:27:56'),
(9, 'APT-1790069787989', 'AKR131', 'Anshika', '8299211106', 'Ultrasound Scan', '2026-09-25', '12:06 PM', '', '', 'Confirmed', '2026-09-22 15:06:28'),
(10, 'APT-20260923-0001', 'AKR131', 'Aman Test', '9519701963', 'Ultrasound Whole Abdomen', '2026-09-25', '02:30 PM', 'Dr. Rajesh Sharma', 'Test scan booking', 'Pending', '2026-09-23 07:15:22'),
(11, 'APT-20260923-0002', 'AKR131', 'Aman Test', '9519701963', 'Ultrasound Whole Abdomen', '2026-09-28', '04:45 PM', 'Dr. Rajesh Sharma', 'Booking verified', 'Pending', '2026-09-23 07:16:20'),
(12, 'APT-20260923-0003', 'AKR131', 'Aman Test 2', '9519701963', 'Ultrasound Whole Abdomen', '2026-09-29', '10:00 AM', 'Dr. Rajesh Sharma', 'Booking verified', 'Pending', '2026-09-23 07:16:59'),
(13, 'APT-20260923-0004', 'AKR139', 'Dr. Verification Test', NULL, 'Ultrasound Whole Abdomen', '2026-10-01', '09:30 AM', 'Dr. Rajesh Sharma (MBBS, MD)', '', 'Pending', '2026-09-23 07:41:51'),
(14, 'APT-20260923-0005', 'AKR140', 'Test', NULL, 'Ultrasound Whole Abdomen', '2026-10-02', '10:00 AM', 'Dr. Rajesh Sharma', '', 'Pending', '2026-09-23 07:42:04'),
(15, 'APT-20260923-0006', 'AKR141', 'Dr. Verification Test', NULL, 'Ultrasound Whole Abdomen', '2026-11-12', '10:10 PM', 'Dr. Rajesh Sharma (MBBS, MD)', '', 'Pending', '2026-09-23 07:42:45'),
(16, 'APT-20260923-0007', 'AKR142', 'Dr. Verification Test', NULL, 'Ultrasound Whole Abdomen', '2026-11-28', '10:47 PM', 'Dr. Rajesh Sharma (MBBS, MD)', '', 'Pending', '2026-09-23 07:42:55'),
(17, 'APT-20260923-0008', 'AKR143', 'Dr. Verification Test', NULL, 'Ultrasound Whole Abdomen', '2026-11-20', '10:48 PM', 'Dr. Rajesh Sharma (MBBS, MD)', '', 'Confirmed', '2026-09-23 07:43:06'),
(18, 'APT-1790168131674', 'AKR131', 'kanhaiya', '9121205444', 'Ultrasound Scan', '2026-09-26', '3:25 PM', NULL, NULL, 'Confirmed', '2026-09-23 18:25:33');

DROP TABLE IF EXISTS `reports`;
CREATE TABLE `reports` (
  `id` int NOT NULL AUTO_INCREMENT,
  `report_id` varchar(20) NOT NULL,
  `patient_id` varchar(20) NOT NULL,
  `patient_name` varchar(100) NOT NULL,
  `report_title` varchar(150) NOT NULL,
  `report_type` varchar(100) DEFAULT NULL,
  `report_date` date NOT NULL,
  `file_name` varchar(255) DEFAULT NULL,
  `file_path` varchar(500) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'Pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `report_id` (`report_id`),
  KEY `patient_id` (`patient_id`),
  CONSTRAINT `reports_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `reports` (`id`, `report_id`, `patient_id`, `patient_name`, `report_title`, `report_type`, `report_date`, `file_name`, `file_path`, `status`, `created_at`) VALUES
(1, 'RPT001', 'AKR001', 'Rahul Kumar', 'Ultrasound Whole Abdomen Report', 'Ultrasound', '2026-09-19', 'Rahul_Ultrasound_Abdomen.pdf', '/reports/Rahul_Ultrasound_Abdomen.pdf', 'Ready', '2026-09-19 12:00:08'),
(2, 'RPT002', 'AKR131', 'Aman Sharma', 'Pelvic Ultrasound Report', 'Ultrasound', '2026-09-19', 'Aman_Pelvic_Scan.pdf', '/reports/Aman_Pelvic_Scan.pdf', 'Ready', '2026-09-19 12:00:08'),
(3, 'RPT003', 'AKR001', 'Priya Singh', 'Thyroid Doppler Report', 'Doppler', '2026-09-19', 'Priya_Thyroid_Doppler.pdf', '/reports/Priya_Thyroid_Doppler.pdf', 'Pending', '2026-09-19 12:00:08'),
(4, 'RPT004', 'AKR001', 'Amit Verma', 'Blood Test Complete Profile', 'Pathology', '2026-09-19', 'Amit_Blood_Test.pdf', '/reports/Amit_Blood_Test.pdf', 'Ready', '2026-09-19 12:00:08'),
(5, 'RPT005', 'AKR001', 'Ravi Gupta', 'Sugar Test Report', 'Pathology', '2026-09-19', 'Ravi_Sugar_Test.pdf', '/reports/Ravi_Sugar_Test.pdf', 'Delivered', '2026-09-19 12:00:08');

DROP TABLE IF EXISTS `payments`;
CREATE TABLE `payments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `payment_id` varchar(20) NOT NULL,
  `patient_id` varchar(20) DEFAULT NULL,
  `patient_name` varchar(100) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_method` varchar(50) DEFAULT NULL,
  `payment_date` date NOT NULL,
  `status` varchar(20) DEFAULT 'Paid',
  `transaction_id` varchar(100) DEFAULT NULL,
  `notes` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `payment_id` (`payment_id`),
  KEY `patient_id` (`patient_id`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `payments` (`id`, `payment_id`, `patient_id`, `patient_name`, `amount`, `payment_method`, `payment_date`, `status`, `transaction_id`, `notes`, `created_at`) VALUES
(1, 'PAY001', 'AKR001', 'Rahul Kumar', '800.00', 'UPI', '2026-09-19', 'Paid', 'UPI983741829', 'Whole abdomen scan paid', '2026-09-19 12:00:08'),
(2, 'PAY002', 'AKR131', 'Aman Sharma', '1000.00', 'UPI', '2026-09-19', 'Paid', 'UPI772819234', 'Pelvic Ultrasound paid online', '2026-09-19 12:00:08'),
(3, 'PAY003', 'AKR001', 'Priya Singh', '450.00', 'Cash', '2026-09-19', 'Partially Paid', 'CSH00291', '200 advance paid in cash', '2026-09-19 12:00:08'),
(4, 'PAY004', 'AKR001', 'Amit Verma', '500.00', 'Cash', '2026-09-19', 'Pending', '', 'Payment pending at counter', '2026-09-19 12:00:08'),
(5, 'PAY005', 'AKR001', 'Ravi Gupta', '150.00', 'Online', '2026-09-19', 'Paid', 'ONL8839210', 'Sugar test fee', '2026-09-19 12:00:08');

DROP TABLE IF EXISTS `notifications`;
CREATE TABLE `notifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `notification_id` varchar(20) NOT NULL,
  `patient_id` varchar(20) DEFAULT NULL,
  `patient_name` varchar(100) DEFAULT NULL,
  `title` varchar(150) NOT NULL,
  `message` text NOT NULL,
  `notification_type` varchar(50) DEFAULT NULL,
  `status` varchar(20) DEFAULT 'Pending',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `is_read` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `notification_id` (`notification_id`),
  KEY `patient_id` (`patient_id`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`patient_id`) REFERENCES `patients` (`patient_id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `notifications` (`id`, `notification_id`, `patient_id`, `patient_name`, `title`, `message`, `notification_type`, `status`, `created_at`, `is_read`) VALUES
(11, 'NTF001', 'AKR001', 'Rahul Kumar', 'Ultrasound Abdomen Report Ready', 'Your ultrasound report has been reviewed and signed by Dr. Rajesh Sharma. Download now.', 'Report', 'Sent', '2026-09-19 12:00:49', 0),
(12, 'NTF002', 'AKR131', 'Aman Sharma', 'Appointment Confirmed for 11:15 AM', 'Your appointment for Pelvic Ultrasound is confirmed. Please arrive 10 minutes before.', 'Appointment', 'Sent', '2026-09-19 12:00:49', 0),
(13, 'NTF003', 'AKR001', 'Rahul Kumar', 'Thyroid Doppler Follow-up Reminder', 'Friendly reminder for your upcoming Doppler scan.', 'Appointment', 'Pending', '2026-09-19 12:00:49', 0),
(14, 'NTF004', 'AKR001', 'Rahul Kumar', 'Payment Receipt Generated', 'Receipt for your scan fee has been generated.', 'Payment', 'Sent', '2026-09-19 12:00:49', 0),
(15, 'NTF005', 'AKR131', 'Aman Sharma', 'Center Timings & Sunday OPD Notice', 'Aakriti Ultrasound center is open 8:00 AM - 8:00 PM Monday through Saturday.', 'General', 'Sent', '2026-09-19 12:00:49', 0),
(16, 'NTF20260923071659', 'AKR131', 'Aman Test 2', 'New Appointment Booked 🔔', 'Aman Test 2 requested Ultrasound Whole Abdomen on 2026-09-29 at 10:00 AM', 'Appointment', 'Sent', '2026-09-23 07:16:59', 0),
(17, 'NTF20260923074150', 'AKR139', 'Dr. Verification Test', 'New Appointment Booked 🔔', 'Dr. Verification Test requested Ultrasound Whole Abdomen on 2026-10-01 at 09:30 AM', 'Appointment', 'Sent', '2026-09-23 07:41:51', 0),
(18, 'NTF20260923074203', 'AKR140', 'Test', 'New Appointment Booked 🔔', 'Test requested Ultrasound Whole Abdomen on 2026-10-02 at 10:00 AM', 'Appointment', 'Sent', '2026-09-23 07:42:04', 0),
(19, 'NTF20260923074245', 'AKR141', 'Dr. Verification Test', 'New Appointment Booked 🔔', 'Dr. Verification Test requested Ultrasound Whole Abdomen on 2026-11-12 at 10:10 PM', 'Appointment', 'Sent', '2026-09-23 07:42:45', 0),
(20, 'NTF20260923074255', 'AKR142', 'Dr. Verification Test', 'New Appointment Booked 🔔', 'Dr. Verification Test requested Ultrasound Whole Abdomen on 2026-11-28 at 10:47 PM', 'Appointment', 'Sent', '2026-09-23 07:42:55', 0),
(21, 'NTF20260923074305', 'AKR143', 'Dr. Verification Test', 'New Appointment Booked 🔔', 'Dr. Verification Test requested Ultrasound Whole Abdomen on 2026-11-20 at 10:48 PM', 'Appointment', 'Sent', '2026-09-23 07:43:06', 0),
(22, 'NTF20260923125533', 'AKR131', 'kanhaiya', 'New Appointment Booked 🔔', 'kanhaiya booked Ultrasound Scan for 2026-09-26', 'Appointment', 'Sent', '2026-09-23 12:55:33', 0),
(23, 'NTF20260923131212', 'AKR131', 'kanhaiya', 'Appointment Confirmed', 'kanhaiya\'s appointment (APT-1790168131674) has been updated to Confirmed.', 'Appointment', 'Sent', '2026-09-23 13:12:12', 0);

DROP TABLE IF EXISTS `fcm_tokens`;
CREATE TABLE `fcm_tokens` (
  `id` int NOT NULL AUTO_INCREMENT,
  `token` varchar(255) NOT NULL,
  `device_type` varchar(50) DEFAULT NULL,
  `user_type` varchar(50) DEFAULT NULL,
  `user_id` varchar(50) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ix_fcm_tokens_token` (`token`),
  KEY `ix_fcm_tokens_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SET FOREIGN_KEY_CHECKS = 1;
