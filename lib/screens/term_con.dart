import 'package:flutter/material.dart';
import 'register_page.dart';

class TermsAndConditionsPage extends StatefulWidget {
  @override
  _TermsAndConditionsPageState createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  bool _isAccepted = false;
  bool _isPrivacyAccepted = false;
  bool _isAgeAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E0),
      appBar: AppBar(
        title: Text(
          'ข้อกำหนดและเงื่อนไข',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            color: const Color(0xFFC76355),
          ),
        ),
        backgroundColor: const Color(0xFFFFF8E1),
        elevation: 0,
        iconTheme: IconThemeData(color: const Color(0xFFC76355)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'ข้อกำหนดและเงื่อนไขการใช้งาน\n\n'
                '1. ข้อกำหนดทั่วไป\n'
                '   1.1 แอปพลิเคชันนี้เป็นเครื่องมือช่วยเตือนการรับประทานยาและติดตามผล ไม่ใช่คำแนะนำทางการแพทย์โดยตรง\n'
                '   1.2 ผู้ใช้ต้องปรึกษาแพทย์หรือเภสัชกรสำหรับข้อมูลด้านการรักษาและการใช้ยา\n'
                '   1.3 ผู้ใช้ต้องมีอายุ 14 ปีขึ้นไป หากอายุต่ำกว่า 18 ปี ต้องได้รับความยินยอมจากผู้ปกครอง\n\n'
                '2. การใช้งานแอปพลิเคชัน\n'
                '   2.1 ผู้ใช้ต้องให้ข้อมูลที่ถูกต้องและเป็นความจริงในการลงทะเบียน\n'
                '   2.2 ผู้ใช้ต้องรับผิดชอบในการรักษาความปลอดภัยของบัญชีและรหัสผ่าน\n'
                '   2.3 ห้ามใช้แอปพลิเคชันในทางที่ผิดกฎหมายหรือละเมิดสิทธิของผู้อื่น\n'
                '   2.4 ผู้ใช้ต้องตั้งค่าการแจ้งเตือนด้วยตนเองและตรวจสอบความถูกต้อง\n\n'
                '3. ความรับผิดชอบและข้อจำกัด\n'
                '   3.1 แอปพลิเคชันไม่รับประกันความถูกต้องของการแจ้งเตือนในทุกกรณี\n'
                '   3.2 ผู้ใช้ต้องตรวจสอบการแจ้งเตือนและเวลารับประทานยาด้วยตนเอง\n'
                '   3.3 ผู้พัฒนาไม่รับผิดชอบต่อความเสียหายที่เกิดจากการใช้งานแอปพลิเคชัน\n'
                '   3.4 ผู้ใช้ควรสำรองข้อมูลการใช้ยาในรูปแบบอื่นเสมอ\n\n'
                '4. ข้อมูลและความเป็นส่วนตัว\n'
                '   4.1 ข้อมูลการใช้ยาและประวัติการรับประทานยาจะถูกเก็บเป็นความลับ\n'
                '   4.2 ข้อมูลจะถูกใช้เพื่อการวิเคราะห์และปรับปรุงการให้บริการเท่านั้น\n'
                '   4.3 ผู้ใช้สามารถขอลบข้อมูลส่วนตัวได้ตามนโยบายความเป็นส่วนตัว\n'
                '   4.4 ข้อมูลการใช้ยาอาจถูกใช้เพื่อการวิจัยในรูปแบบที่ไม่ระบุตัวตน\n\n'
                '5. การแจ้งเตือนและการใช้งาน\n'
                '   5.1 ผู้ใช้ต้องอนุญาตการแจ้งเตือนในอุปกรณ์เพื่อรับการแจ้งเตือน\n'
                '   5.2 แอปพลิเคชันอาจส่งการแจ้งเตือนล่วงหน้าและการแจ้งเตือนซ้ำ\n'
                '   5.3 ผู้ใช้สามารถปรับแต่งการแจ้งเตือนตามความต้องการ\n'
                '   5.4 การแจ้งเตือนอาจล่าช้าหรือไม่ทำงานในกรณีที่ไม่มีการเชื่อมต่ออินเทอร์เน็ต\n\n'
                '6. การยกเลิกและการระงับบัญชี\n'
                '   6.1 ผู้ใช้สามารถยกเลิกการใช้งานได้ทุกเมื่อ\n'
                '   6.2 เราขอสงวนสิทธิ์ในการระงับหรือยกเลิกบัญชีที่ละเมิดข้อกำหนด\n'
                '   6.3 ข้อมูลการใช้งานจะถูกเก็บไว้ตามระยะเวลาที่กฎหมายกำหนด\n'
                '   6.4 ผู้ใช้สามารถขอสำเนาข้อมูลก่อนการยกเลิกบัญชี\n\n'
                '7. การอัพเดทและการเปลี่ยนแปลง\n'
                '   7.1 ข้อกำหนดและเงื่อนไขอาจมีการเปลี่ยนแปลงโดยจะแจ้งให้ทราบล่วงหน้า\n'
                '   7.2 การใช้งานต่อหลังการเปลี่ยนแปลงถือเป็นการยอมรับข้อกำหนดใหม่\n'
                '   7.3 แอปพลิเคชันอาจมีการอัพเดทเพื่อปรับปรุงประสิทธิภาพและความปลอดภัย',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 20),
            CheckboxListTile(
              value: _isAccepted,
              onChanged: (bool? value) {
                setState(() {
                  _isAccepted = value ?? false;
                });
              },
              title: Text(
                'ฉันได้อ่านและยอมรับข้อกำหนดและเงื่อนไขการใช้งาน',
                style: TextStyle(fontSize: 16),
              ),
              activeColor: const Color(0xFFC76355),
            ),
            CheckboxListTile(
              value: _isPrivacyAccepted,
              onChanged: (bool? value) {
                setState(() {
                  _isPrivacyAccepted = value ?? false;
                });
              },
              title: Text(
                'ฉันยินยอมให้จัดเก็บและใช้ข้อมูลส่วนบุคคลตามนโยบายความเป็นส่วนตัว',
                style: TextStyle(fontSize: 16),
              ),
              activeColor: const Color(0xFFC76355),
            ),
            CheckboxListTile(
              value: _isAgeAccepted,
              onChanged: (bool? value) {
                setState(() {
                  _isAgeAccepted = value ?? false;
                });
              },
              title: Text(
                'ฉันยืนยันว่ามีอายุ 14 ปีขึ้นไป',
                style: TextStyle(fontSize: 16),
              ),
              activeColor: const Color(0xFFC76355),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isAccepted && _isPrivacyAccepted && _isAgeAccepted)
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterPage(),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC76355),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'ยอมรับและดำเนินการต่อ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (!(_isAccepted && _isPrivacyAccepted && _isAgeAccepted))
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'กรุณายอมรับเงื่อนไขทั้งหมดเพื่อดำเนินการต่อ',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}