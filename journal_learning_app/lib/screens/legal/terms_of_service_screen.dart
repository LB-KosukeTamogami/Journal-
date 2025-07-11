import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: const Text('利用規約'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Journal Language Learning 利用規約',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ).animate().fadeIn(),
            const SizedBox(height: 8),
            Text(
              '最終更新日: ${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 24),
            _buildSection(
              context,
              '第1条（適用）',
              '本規約は、ユーザーと当社との間の本サービスの利用に関わる一切の関係に適用されるものとします。当社は本サービスに関し、本規約のほか、ご利用にあたってのルール等、各種の定め（以下、「個別規定」といいます。）をすることがあります。これら個別規定はその名称のいかんに関わらず、本規約の一部を構成するものとします。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 200.ms),
            _buildSection(
              context,
              '第2条（利用登録）',
              '1. 登録希望者が本規約に同意の上、当社の定める方法によって利用登録を申請し、当社がこれを承認することによって、利用登録が完了するものとします。\n'
              '2. 当社は、利用登録の申請者に以下の事由があると判断した場合、利用登録の申請を承認しないことがあり、その理由については一切の開示義務を負わないものとします。\n'
              '・利用登録の申請に際して虚偽の事項を届け出た場合\n'
              '・本規約に違反したことがある者からの申請である場合\n'
              '・その他、当社が利用登録を相当でないと判断した場合',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 300.ms),
            _buildSection(
              context,
              '第3条（ユーザーIDおよびパスワードの管理）',
              '1. ユーザーは、自己の責任において、本サービスのユーザーIDおよびパスワードを適切に管理するものとします。\n'
              '2. ユーザーは、いかなる場合にも、ユーザーIDおよびパスワードを第三者に譲渡または貸与し、もしくは第三者と共用することはできません。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 400.ms),
            _buildSection(
              context,
              '第4条（利用料金）',
              '本サービスの基本機能は無料でご利用いただけます。ただし、一部の高度な機能やサービスについては、別途定める利用料金をお支払いいただくことがあります。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 500.ms),
            _buildSection(
              context,
              '第5条（禁止事項）',
              'ユーザーは、本サービスの利用にあたり、以下の行為をしてはなりません。\n'
              '・法令または公序良俗に違反する行為\n'
              '・犯罪行為に関連する行為\n'
              '・サーバーまたはネットワークの機能を破壊したり、妨害したりする行為\n'
              '・当社のサービスの運営を妨害するおそれのある行為\n'
              '・他のユーザーに関する個人情報等を収集または蓄積する行為\n'
              '・不正アクセスをし、またはこれを試みる行為\n'
              '・他のユーザーに成りすます行為\n'
              '・当社のサービスに関連して、反社会的勢力に対して直接または間接に利益を供与する行為\n'
              '・その他、当社が不適切と判断する行為',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 600.ms),
            _buildSection(
              context,
              '第6条（本サービスの提供の停止等）',
              '1. 当社は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく本サービスの全部または一部の提供を停止または中断することができるものとします。\n'
              '・本サービスにかかるコンピュータシステムの保守点検または更新を行う場合\n'
              '・地震、落雷、火災、停電または天災などの不可抗力により、本サービスの提供が困難となった場合\n'
              '・コンピュータまたは通信回線等が事故により停止した場合\n'
              '・その他、当社が本サービスの提供が困難と判断した場合\n'
              '2. 当社は、本サービスの提供の停止または中断により、ユーザーまたは第三者が被ったいかなる不利益または損害についても、一切の責任を負わないものとします。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 700.ms),
            _buildSection(
              context,
              '第7条（知的財産権）',
              '本サービスおよび本サービスに関連する一切の情報についての著作権およびその他の知的財産権はすべて当社または当社にその利用を許諾した権利者に帰属し、ユーザーは無断で複製、譲渡、貸与、翻訳、改変、転載、公衆送信（送信可能化を含みます。）、伝送、配布、出版、営業使用等をしてはならないものとします。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 800.ms),
            _buildSection(
              context,
              '第8条（個人情報の取扱い）',
              '当社は、本サービスの利用によって取得する個人情報については、当社「プライバシーポリシー」に従い適切に取り扱うものとします。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 900.ms),
            _buildSection(
              context,
              '第9条（免責事項）',
              '1. 当社は、本サービスに事実上または法律上の瑕疵（安全性、信頼性、正確性、完全性、有効性、特定の目的への適合性、セキュリティなどに関する欠陥、エラーやバグ、権利侵害などを含みます。）がないことを明示的にも黙示的にも保証しておりません。\n'
              '2. 当社は、本サービスに起因してユーザーに生じたあらゆる損害について、当社の故意又は重過失による場合を除き、一切の責任を負いません。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 1000.ms),
            _buildSection(
              context,
              '第10条（サービス内容の変更等）',
              '当社は、ユーザーへの事前の告知をもって、本サービスの内容を変更、追加または廃止することがあり、ユーザーはこれを承諾するものとします。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 1100.ms),
            _buildSection(
              context,
              '第11条（利用規約の変更）',
              '1. 当社は、ユーザーの個別の同意を要せず、本規約を変更することができるものとします。\n'
              '2. 当社は、本規約を変更する場合には、その効力発生日を定め、効力発生日までに当社ウェブサイト上での掲示その他の方法により、変更内容および効力発生日を周知するものとします。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 1200.ms),
            _buildSection(
              context,
              '第12条（準拠法・裁判管轄）',
              '1. 本規約の解釈にあたっては、日本法を準拠法とします。\n'
              '2. 本サービスに関して紛争が生じた場合には、当社の本店所在地を管轄する裁判所を専属的合意管轄とします。',
            ).animate().slideX(begin: -0.1, duration: 300.ms, delay: 1300.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}