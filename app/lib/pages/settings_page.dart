import 'package:app/components/category_dialog.dart';
import 'package:app/models/models.dart';
import 'package:app/themes/app_colors.dart';
import 'package:app/utils/data_exporter.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.profile,
    required this.onUpdateProfile,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.notificationSettings,
    required this.onUpdateNotificationSettings,
    required this.tasks,
    required this.notes,
    required this.categories,
    this.isCloudConnected = false,
    this.onConnectCloud,
    this.onResetData,
    this.onLogout,
    super.key,
  });

  final UserProfile profile;
  final ValueChanged<UserProfile> onUpdateProfile;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final NotificationSettings notificationSettings;
  final ValueChanged<NotificationSettings> onUpdateNotificationSettings;
  final List<Task> tasks;
  final List<Note> notes;
  final List<Category> categories;
  final bool isCloudConnected;
  final VoidCallback? onConnectCloud;
  final VoidCallback? onResetData;
  final VoidCallback? onLogout;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late String _selectedIcon;
  late String _selectedColor;
  bool _showPasswordSection = false;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.profile.displayName,
    );
    _usernameController = TextEditingController(text: widget.profile.username);
    _selectedIcon = widget.profile.avatarIcon;
    _selectedColor = widget.profile.avatarColor;
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _displayNameController.text = widget.profile.displayName;
      _usernameController.text = widget.profile.username;
      _selectedIcon = widget.profile.avatarIcon;
      _selectedColor = widget.profile.avatarColor;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final name = _displayNameController.text.trim();
    final user = _usernameController.text.trim();
    if (name.isEmpty || user.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.destructive,
          content: Text('Nome e usuário não podem ficar vazios.'),
        ),
      );
      return;
    }

    widget.onUpdateProfile(
      widget.profile.copyWith(
        displayName: name,
        username: user,
        avatarIcon: _selectedIcon,
        avatarColor: _selectedColor,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado com sucesso!')),
    );
  }

  void _savePassword() {
    final current = _currentPasswordController.text;
    final next = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || next.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.destructive,
          content: Text('Preencha a senha atual e a nova senha.'),
        ),
      );
      return;
    }
    if (next.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.destructive,
          content: Text('A nova senha deve ter pelo menos 4 caracteres.'),
        ),
      );
      return;
    }
    if (next != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.destructive,
          content: Text('A confirmação de senha não confere.'),
        ),
      );
      return;
    }

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    setState(() => _showPasswordSection = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Senha alterada com sucesso!')),
    );
  }

  Future<void> _toggleDeviceNotifications(bool value) async {
    if (value) {
      try {
        await Permission.notification.request();
      } catch (_) {}
    }
    widget.onUpdateNotificationSettings(
      widget.notificationSettings.copyWith(enabled: value),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Notificações ativadas!'
              : 'Notificações do dispositivo desativadas.',
        ),
      ),
    );
  }

  void _confirmResetData() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackGround,
        title: const Text(
          'Resetar Dados',
          style: TextStyle(fontFamily: 'Playfair Display'),
        ),
        content: const Text(
          'Isso vai restaurar todas as tarefas, notas e categorias para os padrões iniciais. Tem certeza?',
          style: TextStyle(fontFamily: 'Lora', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onResetData?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dados resetados com sucesso!')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: const Text('Resetar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final cardBg = isDark
        ? AppColors.darkCardBackground
        : AppColors.cardBackGround;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.border;
    final textPrimary = isDark ? AppColors.darkOnSurface : AppColors.onPrimary;
    final textMuted = isDark ? AppColors.darkOnMuted : AppColors.onMuted;
    final mutedBg = isDark ? AppColors.darkMuted : AppColors.muted;

    final avatarColor = parseHexColor(_selectedColor);
    final avatarIcon = iconDataFromName(_selectedIcon);
    final notif = widget.notificationSettings;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho da Página
              Text(
                'Configurações',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Personalize seu perfil, aparência, alertas e exporte seus dados',
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 13,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 22),

              // ============================================================
              // 1. SEÇÃO: PERFIL DO USUÁRIO
              // ============================================================
              _SettingsSectionCard(
                icon: LucideIcons.user,
                title: 'Perfil do Usuário',
                subtitle: 'Edite suas informações pessoais, avatar e senha',
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textMuted: textMuted,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview do Avatar
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: mutedBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: avatarColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              avatarIcon,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _displayNameController.text.trim().isEmpty
                                      ? 'Sem nome'
                                      : _displayNameController.text.trim(),
                                  style: TextStyle(
                                    fontFamily: 'Playfair Display',
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _usernameController.text.trim(),
                                  style: TextStyle(
                                    fontFamily: 'Lora',
                                    fontSize: 13,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nome de Exibição
                    Text(
                      'Nome de Exibição',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _displayNameController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 14,
                        color: textPrimary,
                      ),
                      decoration: _inputDecoration(
                        hint: 'Ex.: Bruno Silva',
                        bgColor: bgColor,
                        borderColor: borderColor,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Usuário / E-mail
                    Text(
                      'Usuário / E-mail',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _usernameController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 14,
                        color: textPrimary,
                      ),
                      decoration: _inputDecoration(
                        hint: 'Ex.: usuario@email.com',
                        bgColor: bgColor,
                        borderColor: borderColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cor do Avatar
                    Text(
                      'Cor do Avatar',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kCategoryColorOptions.map((hex) {
                        final isSelected = _selectedColor == hex;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = hex),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: parseHexColor(hex),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? textPrimary
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Ícone do Avatar
                    Text(
                      'Ícone do Avatar',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: kCategoryIconOptions.map((iconName) {
                        final isSelected = _selectedIcon == iconName;
                        return InkWell(
                          onTap: () => setState(() => _selectedIcon = iconName),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : bgColor,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : borderColor,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  iconDataFromName(iconName),
                                  size: 14,
                                  color: isSelected ? Colors.white : textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  iconName,
                                  style: TextStyle(
                                    fontFamily: 'Lora',
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Botões: Salvar Perfil + Alterar Senha
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        FilledButton.icon(
                          onPressed: _saveProfile,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(LucideIcons.check, size: 16),
                          label: const Text(
                            'Salvar Perfil',
                            style: TextStyle(fontFamily: 'Lora', fontSize: 13),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => setState(
                            () => _showPasswordSection = !_showPasswordSection,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: borderColor),
                            foregroundColor: textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(LucideIcons.lock, size: 15),
                          label: Text(
                            _showPasswordSection
                                ? 'Ocultar Senha'
                                : 'Alterar Senha',
                            style: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Subseção: Alterar Senha
                    if (_showPasswordSection) ...[
                      const SizedBox(height: 16),
                      Divider(color: borderColor),
                      const SizedBox(height: 12),
                      Text(
                        'Alterar Senha',
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _currentPasswordController,
                        obscureText: true,
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 14,
                          color: textPrimary,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Senha atual',
                          bgColor: bgColor,
                          borderColor: borderColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 14,
                          color: textPrimary,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Nova senha (mín. 4 caracteres)',
                          bgColor: bgColor,
                          borderColor: borderColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 14,
                          color: textPrimary,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Confirmar nova senha',
                          bgColor: bgColor,
                          borderColor: borderColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _savePassword,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(LucideIcons.keyRound, size: 15),
                          label: const Text(
                            'Atualizar Senha',
                            style: TextStyle(fontFamily: 'Lora', fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ============================================================
              // 2. SEÇÃO: TEMAS E APARÊNCIA
              // ============================================================
              _SettingsSectionCard(
                icon: LucideIcons.palette,
                title: 'Aparência e Tema',
                subtitle: 'Escolha o estilo visual do seu caderno',
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textMuted: textMuted,
                child: Row(
                  children: [
                    Expanded(
                      child: _ThemeOptionCard(
                        label: 'Claro',
                        subtitle: 'Pergaminho',
                        icon: LucideIcons.sun,
                        selected: widget.themeMode == ThemeMode.light,
                        onTap: () =>
                            widget.onThemeModeChanged(ThemeMode.light),
                        bgColor: bgColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ThemeOptionCard(
                        label: 'Escuro',
                        subtitle: 'Noturno',
                        icon: LucideIcons.moon,
                        selected: widget.themeMode == ThemeMode.dark,
                        onTap: () => widget.onThemeModeChanged(ThemeMode.dark),
                        bgColor: bgColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ThemeOptionCard(
                        label: 'Sistema',
                        subtitle: 'Automático',
                        icon: LucideIcons.monitor,
                        selected: widget.themeMode == ThemeMode.system,
                        onTap: () =>
                            widget.onThemeModeChanged(ThemeMode.system),
                        bgColor: bgColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ============================================================
              // 3. SEÇÃO: NOTIFICAÇÕES
              // ============================================================
              _SettingsSectionCard(
                icon: LucideIcons.bell,
                title: 'Notificações e Alertas',
                subtitle: 'Configure como deseja ser avisado sobre seus prazos',
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textMuted: textMuted,
                child: Column(
                  children: [
                    _NotificationToggleTile(
                      title: 'Notificações do Dispositivo',
                      subtitle:
                          'Receber alertas mesmo com o aplicativo em segundo plano',
                      value: notif.enabled,
                      onChanged: _toggleDeviceNotifications,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    Divider(color: borderColor, height: 16),
                    _NotificationToggleTile(
                      title: 'Alertas Críticos',
                      subtitle: 'Tarefas em atraso ou vencendo em até 1 hora',
                      value: notif.enabled && notif.criticalAlerts,
                      onChanged: notif.enabled
                          ? (v) => widget.onUpdateNotificationSettings(
                              notif.copyWith(criticalAlerts: v),
                            )
                          : null,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    _NotificationToggleTile(
                      title: 'Alertas Urgentes',
                      subtitle: 'Tarefas vencendo nas próximas 6 horas',
                      value: notif.enabled && notif.highAlerts,
                      onChanged: notif.enabled
                          ? (v) => widget.onUpdateNotificationSettings(
                              notif.copyWith(highAlerts: v),
                            )
                          : null,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    _NotificationToggleTile(
                      title: 'Lembretes Próximos',
                      subtitle: 'Tarefas que vencem hoje (até 24 horas)',
                      value: notif.enabled && notif.mediumAlerts,
                      onChanged: notif.enabled
                          ? (v) => widget.onUpdateNotificationSettings(
                              notif.copyWith(mediumAlerts: v),
                            )
                          : null,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                    _NotificationToggleTile(
                      title: 'Som e Vibração',
                      subtitle: 'Emitir alerta sonoro nas notificações urgentes',
                      value: notif.enabled && notif.soundAndVibration,
                      onChanged: notif.enabled
                          ? (v) => widget.onUpdateNotificationSettings(
                              notif.copyWith(soundAndVibration: v),
                            )
                          : null,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ============================================================
              // 4. SEÇÃO: EXPORTAR E GERENCIAR DADOS
              // ============================================================
              _SettingsSectionCard(
                icon: LucideIcons.download,
                title: 'Exportação e Dados',
                subtitle:
                    'Exporte suas tarefas e anotações ou faça backup completo',
                cardBg: cardBg,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textMuted: textMuted,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resumo de registros
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: mutedBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _DataCountBadge(
                            label: 'Tarefas',
                            count: widget.tasks.length,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                          _DataCountBadge(
                            label: 'Anotações',
                            count: widget.notes.length,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                          _DataCountBadge(
                            label: 'Categorias',
                            count: widget.categories.length,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Exportar Tarefas',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.tasks.isEmpty
                                ? null
                                : () {
                                    DataExporter.exportTasksCsv(
                                      widget.tasks,
                                      widget.categories,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${widget.tasks.length} tarefas exportadas para CSV',
                                        ),
                                      ),
                                    );
                                  },
                            style: _outlinedBtnStyle(borderColor, textPrimary),
                            icon: const Icon(LucideIcons.sheet, size: 15),
                            label: const Text(
                              'Tarefas CSV',
                              style: TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.tasks.isEmpty
                                ? null
                                : () {
                                    DataExporter.exportTasksPdf(
                                      widget.tasks,
                                      widget.categories,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${widget.tasks.length} tarefas exportadas para PDF',
                                        ),
                                      ),
                                    );
                                  },
                            style: _outlinedBtnStyle(borderColor, textPrimary),
                            icon: const Icon(LucideIcons.fileText, size: 15),
                            label: const Text(
                              'Tarefas PDF',
                              style: TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Exportar Anotações',
                      style: TextStyle(
                        fontFamily: 'Lora',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.notes.isEmpty
                                ? null
                                : () {
                                    DataExporter.exportNotesCsv(
                                      widget.notes,
                                      widget.categories,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${widget.notes.length} anotações exportadas para CSV',
                                        ),
                                      ),
                                    );
                                  },
                            style: _outlinedBtnStyle(borderColor, textPrimary),
                            icon: const Icon(LucideIcons.sheet, size: 15),
                            label: const Text(
                              'Anotações CSV',
                              style: TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.notes.isEmpty
                                ? null
                                : () {
                                    DataExporter.exportNotesPdf(
                                      widget.notes,
                                      widget.categories,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${widget.notes.length} anotações exportadas para PDF',
                                        ),
                                      ),
                                    );
                                  },
                            style: _outlinedBtnStyle(borderColor, textPrimary),
                            icon: const Icon(LucideIcons.fileText, size: 15),
                            label: const Text(
                              'Anotações PDF',
                              style: TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Backup Completo JSON
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          DataExporter.exportFullBackupJson(
                            tasks: widget.tasks,
                            notes: widget.notes,
                            categories: widget.categories,
                            profile: widget.profile,
                            notificationSettings: widget.notificationSettings,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Backup completo (JSON) gerado com sucesso!',
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(LucideIcons.databaseBackup, size: 16),
                        label: const Text(
                          'Exportar Backup Completo (JSON)',
                          style: TextStyle(fontFamily: 'Lora', fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Zona de Perigo
                    Divider(color: borderColor),
                    const SizedBox(height: 12),
                    Text(
                      'Zona de Perigo',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.destructive,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _confirmResetData,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.destructive,
                              ),
                              foregroundColor: AppColors.destructive,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(LucideIcons.rotateCcw, size: 15),
                            label: const Text(
                              'Resetar Dados',
                              style: TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        if (widget.isCloudConnected &&
                            widget.onLogout != null) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onLogout,
                              style: _outlinedBtnStyle(
                                borderColor,
                                textPrimary,
                              ),
                              icon: const Icon(LucideIcons.logOut, size: 15),
                              label: const Text(
                                'Usar só Offline',
                                style: TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ] else if (!widget.isCloudConnected &&
                            widget.onConnectCloud != null) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onConnectCloud,
                              style: _outlinedBtnStyle(
                                borderColor,
                                textPrimary,
                              ),
                              icon: const Icon(
                                LucideIcons.cloudUpload,
                                size: 15,
                              ),
                              label: const Text(
                                'Conectar Nuvem',
                                style: TextStyle(
                                  fontFamily: 'Lora',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required Color bgColor,
    required Color borderColor,
  }) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: bgColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
    );
  }

  ButtonStyle _outlinedBtnStyle(Color borderColor, Color textColor) {
    return OutlinedButton.styleFrom(
      side: BorderSide(color: borderColor),
      foregroundColor: textColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.textMuted,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final Color textMuted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.bgColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textMuted,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color bgColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : borderColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primary : textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: selected ? AppColors.primary : textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 14,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationToggleTile extends StatelessWidget {
  const _NotificationToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.textPrimary,
    required this.textMuted,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: AppColors.primary,
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Lora',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onChanged != null ? textPrimary : textMuted,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Lora',
          fontSize: 12,
          color: textMuted,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _DataCountBadge extends StatelessWidget {
  const _DataCountBadge({
    required this.label,
    required this.count,
    required this.textPrimary,
    required this.textMuted,
  });

  final String label;
  final int count;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontFamily: 'Playfair Display',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Lora',
            fontSize: 11,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}
