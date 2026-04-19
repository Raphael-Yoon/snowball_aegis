{% extends 'link2_base.jsp' %}

{# ================================================================
   APD 섹션 (Q6~Q33)  Access to Program & Data

   공통 섹션 답변(answers[3]=use_cloud, answers[4]=cloud_type)은
   Jinja로 전달받아 JS 초기값으로 사용.

   조건 정리:
   ─ Q6 (apd15_shared_account) = N → Q9 표시, Q10~Q12 숨김
   ─ Q6 = Y                        → Q9 숨김, Q10~Q12 표시
   ─ SaaS → Q13 숨김, Q16~Q32 숨김
   ─ PaaS → Q16~Q32 숨김
   ─ IaaS → Q24, Q31 숨김
   ─ Q16(apd07_db_access) = N → Q17~Q25 숨김
   ─ Q26(apd12_os_access)  = N → Q27~Q32 숨김
================================================================ #}

{% macro yn_field(idx, answers) %}
<input type="hidden" id="q{{ idx }}_hidden" name="q{{ idx }}" value="{{ answers[idx] }}">
<div class="yn-wrap">
    <button type="button" id="q{{ idx }}_yes" onclick="setYN({{ idx }},'Y')"
            style="width:80px" class="btn btn-sm {% if answers[idx]=='Y' %}btn-primary{% else %}btn-outline-secondary{% endif %}">
        <i class="fas fa-check me-1"></i>예
    </button>
    <button type="button" id="q{{ idx }}_no" onclick="setYN({{ idx }},'N')"
            style="width:80px" class="btn btn-sm {% if answers[idx]=='N' %}btn-primary{% else %}btn-outline-secondary{% endif %}">
        <i class="fas fa-times me-1"></i>아니요
    </button>
</div>
{% endmacro %}

{% macro type4_field(idx, q, answers, textarea_answers) %}
<div class="mt-1">
    <div class="form-check mb-1">
        <input class="form-check-input" type="radio" name="q{{ idx }}" value="Y"
               id="q{{ idx }}_r_yes" onchange="toggleTextarea4({{ idx }})"
               {% if answers[idx]=='Y' %}checked{% endif %}>
        <label class="form-check-label" for="q{{ idx }}_r_yes">예</label>
    </div>
    <div class="form-check mt-1">
        <input class="form-check-input" type="radio" name="q{{ idx }}" value="N"
               id="q{{ idx }}_r_no" onchange="toggleTextarea4({{ idx }})"
               {% if answers[idx]=='N' %}checked{% endif %}>
        <label class="form-check-label" for="q{{ idx }}_r_no">아니요</label>
    </div>
    <div id="q{{ idx }}_ta_wrap" class="mt-2{% if answers[idx] != 'Y' %} d-none{% endif %}">
        <textarea class="form-control" name="q{{ idx }}_text" id="q{{ idx }}_ta"
                  rows="5"
                  {% if answers[idx] == 'Y' %}required{% endif %}>{{ textarea_answers[idx] }}</textarea>
    </div>
</div>
{% endmacro %}

{% macro type3_4_field(idx, q, answers, textarea_answers, textarea2_answers) %}
<div class="mt-1">
    <div class="form-check mb-1">
        <input class="form-check-input" type="radio" name="q{{ idx }}" value="Y"
               id="q{{ idx }}_r_yes" required onchange="toggleType34({{ idx }})"
               {% if answers[idx]=='Y' %}checked{% endif %}>
        <label class="form-check-label" for="q{{ idx }}_r_yes">예</label>
    </div>
    <div class="form-check mt-1">
        <input class="form-check-input" type="radio" name="q{{ idx }}" value="N"
               id="q{{ idx }}_r_no" onchange="toggleType34({{ idx }})"
               {% if answers[idx]=='N' %}checked{% endif %}>
        <label class="form-check-label" for="q{{ idx }}_r_no">아니요</label>
    </div>
    <div id="q{{ idx }}_34_wrap" class="mt-2{% if answers[idx] != 'Y' %} d-none{% endif %}">
        <label class="form-label small text-muted mb-1">도구명</label>
        <input type="text" class="form-control mb-2" name="q{{ idx }}_text"
               id="q{{ idx }}_text_input"
               value="{{ textarea_answers[idx] }}"
               data-orig-placeholder="{{ q.text_help or '제품명을 입력하세요' }}"
               placeholder="{{ (q.text_help or '제품명을 입력하세요') if answers[idx]=='Y' else '' }}"
               {% if answers[idx] == 'Y' %}required{% endif %}>
        <label class="form-label small text-muted mb-1">접속 절차</label>
        <textarea class="form-control" name="q{{ idx }}_text2" id="q{{ idx }}_ta2"
                  rows="4"
                  {% if answers[idx] == 'Y' %}required{% endif %}>{{ textarea2_answers[idx] }}</textarea>
    </div>
</div>
{% endmacro %}

{% macro type3_field(idx, q, answers, textarea_answers) %}
<div class="mt-1">
    <div class="form-check mb-1">
        <input class="form-check-input" type="radio" name="q{{ idx }}" value="Y"
               id="q{{ idx }}_r_yes" required onchange="toggleTextInput3({{ idx }})"
               {% if answers[idx]=='Y' %}checked{% endif %}>
        <label class="form-check-label" for="q{{ idx }}_r_yes">예</label>
    </div>
    <input type="text" class="form-control mb-1" name="q{{ idx }}_text"
           id="q{{ idx }}_text_input"
           placeholder="{{ (q.text_help or '제품명을 입력하세요') if answers[idx]=='Y' else '' }}"
           value="{{ textarea_answers[idx] }}"
           data-orig-placeholder="{{ q.text_help or '제품명을 입력하세요' }}"
           {% if answers[idx] != 'Y' %}disabled style="background-color:#e9ecef; cursor:not-allowed;"
           {% else %}required{% endif %}>
    <div class="form-check">
        <input class="form-check-input" type="radio" name="q{{ idx }}" value="N"
               id="q{{ idx }}_r_no" onchange="toggleTextInput3({{ idx }})"
               {% if answers[idx]=='N' %}checked{% endif %}>
        <label class="form-check-label" for="q{{ idx }}_r_no">아니요</label>
    </div>
</div>
{% endmacro %}

{% block section_content %}
{% set qs = section_questions %}

{# ── 접근권한 공통 그룹 (Q6~Q8) ── #}
<div class="sub-section-title"><i class="fas fa-user-shield me-1"></i>접근권한 관리</div>

{# Q6: apd15_shared_account (type 1) ← 분기점 #}
{% set q = qs[0] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3 border-warning">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }} <span class="badge bg-warning text-dark ms-1">분기점</span></div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ yn_field(idx, answers) }}
    </div>
</div>

{# Q7: apd01_auth_history (type 1) #}
{% set q = qs[1] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ yn_field(idx, answers) }}
    </div>
</div>

{# Q8: apd02_revoke_history (type 1) #}
{% set q = qs[2] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ yn_field(idx, answers) }}
    </div>
</div>

{# Q9: apd15_shared_mgmt (type 5) — Q6=N 시만 표시 #}
{% set q = qs[3] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        <textarea class="form-control" name="q{{ idx }}"
                  placeholder="{{ q.text_help or '관련 내용을 입력하세요.' }}" rows="4">{{ answers[idx] }}</textarea>
    </div>
</div>

{# Q10: apd01_procedure (type 4) — Q8=Y 시만 표시 #}
{% set q = qs[4] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ type4_field(idx, q, answers, textarea_answers) }}
    </div>
</div>

{# Q11: apd02_procedure (type 4) — Q8=Y 시만 표시 #}
{% set q = qs[5] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ type4_field(idx, q, answers, textarea_answers) }}
    </div>
</div>

{# Q12: apd03_procedure (type 4) — Q8=Y 시만 표시 #}
{% set q = qs[6] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ type4_field(idx, q, answers, textarea_answers) }}
    </div>
</div>

{# Q13: apd04_admin (type 5) — SaaS+SOC1 시 숨김 #}
{% set q = qs[7] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        <textarea class="form-control" name="q{{ idx }}"
                  placeholder="{{ q.text_help or '관련 내용을 입력하세요.' }}" rows="4">{{ answers[idx] }}</textarea>
    </div>
</div>

{# Q14: apd05_monitoring (type 1) #}
{% set q = qs[8] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ yn_field(idx, answers) }}
    </div>
</div>

{# Q15: apd06_password (type 5) #}
{% set q = qs[9] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        <textarea class="form-control" name="q{{ idx }}"
                  placeholder="{{ q.text_help or '패스워드 설정 사항을 입력하세요.' }}" rows="4">{{ answers[idx] }}</textarea>
    </div>
</div>

{# ── DB 관련 그룹 (Q16~Q25) ── #}
<div class="section-divider">
    <div class="sub-section-title"><i class="fas fa-database me-1"></i>DB 접근권한</div>
</div>

{# Q16: apd07_db_access (type 1) ← DB 분기점 #}
{% set q = qs[10] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3 border-warning">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }} <span class="badge bg-warning text-dark ms-1">분기점</span></div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ yn_field(idx, answers) }}
    </div>
</div>

{# Q17: apd09_db_tool (type 3, Y/N + text) #}
{% set q = qs[15] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ type3_field(idx, q, answers, textarea_answers) }}
    </div>
</div>

{# Q18: apd07_data_history (type 1) #}
{% set q = qs[11] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ yn_field(idx, answers) }}
    </div>
</div>

{# Q19: apd07_procedure (type 4) #}
{% set q = qs[12] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ type4_field(idx, q, answers, textarea_answers) }}
    </div>
</div>

{# Q19: apd08_data_auth (type 5) #}
{% set q = qs[13] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        <textarea class="form-control" name="q{{ idx }}"
                  placeholder="{{ q.text_help or '관련 내용을 입력하세요.' }}" rows="4">{{ answers[idx] }}</textarea>
    </div>
</div>

{# Q20: apd09_db_type (type 5) #}
{% set q = qs[14] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        <textarea class="form-control" name="q{{ idx }}"
                  placeholder="{{ q.text_help or 'DB 종류와 버전을 입력하세요.' }}" rows="3">{{ answers[idx] }}</textarea>
    </div>
</div>

{# Q22: apd09_db_history (type 1) #}
{% set q = qs[16] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ yn_field(idx, answers) }}
    </div>
</div>

{# Q23: apd09_procedure (type 4) #}
{% set q = qs[17] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ type4_field(idx, q, answers, textarea_answers) }}
    </div>
</div>

{# Q24: apd10_db_admin (type 5) — IaaS+SOC1 시 추가 숨김 #}
{% set q = qs[18] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        <textarea class="form-control" name="q{{ idx }}"
                  placeholder="{{ q.text_help or 'DB 관리자 권한 보유 인원을 입력하세요.' }}" rows="3">{{ answers[idx] }}</textarea>
    </div>
</div>

{# Q25: apd11_db_password (type 5) #}
{% set q = qs[19] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        <textarea class="form-control" name="q{{ idx }}"
                  placeholder="{{ q.text_help or 'DB 패스워드 설정 사항을 입력하세요.' }}" rows="3">{{ answers[idx] }}</textarea>
    </div>
</div>

{# ── OS 관련 그룹 (Q26~Q32) ── #}
<div class="section-divider">
    <div class="sub-section-title"><i class="fas fa-server me-1"></i>OS 접근권한</div>
</div>

{# Q26: apd12_os_access (type 1) ← OS 분기점 #}
{% set q = qs[20] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3 border-warning">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }} <span class="badge bg-warning text-dark ms-1">분기점</span></div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ yn_field(idx, answers) }}
    </div>
</div>

{# Q27: apd12_os_tool (type 3: Y/N + textbox) #}
{% set q = qs[22] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ type3_field(idx, q, answers, textarea_answers) }}
    </div>
</div>

{# Q28: apd12_os_type (type 5) #}
{% set q = qs[21] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        <textarea class="form-control" name="q{{ idx }}"
                  placeholder="{{ q.text_help or 'OS 종류와 버전을 입력하세요.' }}" rows="3">{{ answers[idx] }}</textarea>
    </div>
</div>

{# Q29: apd12_os_history (type 1) #}
{% set q = qs[23] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ yn_field(idx, answers) }}
    </div>
</div>

{# Q30: apd12_procedure (type 4) #}
{% set q = qs[24] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ type4_field(idx, q, answers, textarea_answers) }}
    </div>
</div>

{# Q31: apd13_os_admin (type 5) — IaaS+SOC1 시 추가 숨김 #}
{% set q = qs[25] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        <textarea class="form-control" name="q{{ idx }}"
                  placeholder="{{ q.text_help or 'OS 관리자 권한 보유 인원을 입력하세요.' }}" rows="3">{{ answers[idx] }}</textarea>
    </div>
</div>

{# Q32: apd14_os_password (type 5) #}
{% set q = qs[26] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        <textarea class="form-control" name="q{{ idx }}"
                  placeholder="{{ q.text_help or 'OS 패스워드 설정 사항을 입력하세요.' }}" rows="3">{{ answers[idx] }}</textarea>
    </div>
</div>

{# ── VPN (Q33) ── #}
<div class="section-divider">
    <div class="sub-section-title"><i class="fas fa-shield-alt me-1"></i>외부 접속</div>
</div>

{# Q33: apd16_vpn (type 1) #}
{% set q = qs[27] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ yn_field(idx, answers) }}
    </div>
</div>

{% endblock %}


{% block section_scripts %}
<script>
// 공통 섹션에서 저장된 값 (Jinja로 초기 전달)
const _cloudType = '{{ answers[Q_ID["cloud_type"]] }}';

// type3+4 (Y/N + textbox + textarea) 토글
function toggleType34(idx) {
    const wrap   = document.getElementById(`q${idx}_34_wrap`);
    const textEl = document.getElementById(`q${idx}_text_input`);
    const ta2    = document.getElementById(`q${idx}_ta2`);
    const yesR   = document.querySelector(`input[name="q${idx}"][value="Y"]`);
    if (!wrap || !yesR) return;
    if (yesR.checked) {
        wrap.classList.remove('d-none');
        if (textEl) { textEl.required = true; textEl.placeholder = textEl.dataset.origPlaceholder || ''; }
        if (ta2)    { ta2.required = true; }
    } else {
        wrap.classList.add('d-none');
        if (textEl) { textEl.value = ''; textEl.required = false; textEl.placeholder = ''; }
        if (ta2)    { ta2.value = ''; ta2.required = false; }
    }
}

function applyConditions() {
    const isSaaS = (_cloudType === 'SaaS');
    const isPaaS = (_cloudType === 'PaaS');
    const isIaaS = (_cloudType === 'IaaS');

    // ── Q6(shared_account) 분기점 ────────────────────────────────
    const shared = getVal(6);
    toggleQ(9,  shared === 'N');           // apd15_shared_mgmt: N 시 표시
    toggleRange(10, 12, shared === 'Y');   // apd01~03_procedure: Y 시 표시

    // ── SaaS → Q13(apd04_admin) 숨김 ─────────────────────────────
    toggleQ(13, !isSaaS);

    // ── DB 그룹 가시성 ────────────────────────────────────────────
    const showDB = !(isSaaS || isPaaS);
    toggleRange(16, 25, showDB);
    if (showDB) {
        const dbAccess = getVal(16);
        const dbSubShow = (dbAccess === 'Y');
        toggleRange(17, 25, dbSubShow);
        // IaaS: apd10_db_admin(Q24) 추가 숨김
        if (dbSubShow && isIaaS) toggleQ(24, false);
    }

    // ── OS 그룹 가시성 ────────────────────────────────────────────
    const showOS = !(isSaaS || isPaaS);
    toggleRange(26, 32, showOS);
    if (showOS) {
        const osAccess = getVal(26);
        const osSubShow = (osAccess === 'Y');
        toggleRange(27, 32, osSubShow);
        // IaaS: apd13_os_admin(Q31) 추가 숨김
        if (osSubShow && isIaaS) toggleQ(31, false);
    }
}

function fillAllSamples() {
    setYN(6, 'Y');   // auth_history
    setYN(7, 'Y');   // revoke_history
    setYN(8, 'Y');   // shared_account (개인별 발급)
    // Q9 숨겨짐 (shared=Y)
    // Q10~12 표시
    document.querySelector('input[name="q10"][value="Y"]').checked = true; toggleTextarea4(10); document.getElementById('q10_ta').value = '부서장 승인 후 IT팀 처리';
    document.querySelector('input[name="q11"][value="Y"]').checked = true; toggleTextarea4(11); document.getElementById('q11_ta').value = '부서이동 시 HR 연동 자동 회수';
    document.querySelector('input[name="q12"][value="Y"]').checked = true; toggleTextarea4(12); document.getElementById('q12_ta').value = '퇴사 당일 계정 비활성화';
    document.querySelector('textarea[name="q13"]').value = '시스템관리자 1명';
    setYN(14, 'Y');
    document.querySelector('textarea[name="q15"]').value = '최소 8자, 대소문자+숫자 조합, 90일 주기 변경';
    setYN(16, 'Y');  // db_access
    setYN(17, 'Y');
    document.querySelector('input[name="q18"][value="Y"]').checked = true; toggleTextarea4(18); document.getElementById('q18_ta').value = '변경 요청서 작성 후 DBA 검토·승인, 변경 스크립트 실행 및 결과 확인';
    document.querySelector('textarea[name="q19"]').value = 'DBA 홍길동';
    document.querySelector('textarea[name="q20"]').value = 'Oracle 19c';
    // Q21 (db_tool): Y + text
    document.querySelector('input[name="q21"][value="Y"]').checked = true;
    toggleTextInput3(21);
    document.getElementById('q21_text_input').value = 'Imperva DAM';
    setYN(22, 'Y');
    document.querySelector('input[name="q23"][value="Y"]').checked = true; toggleTextarea4(23); document.getElementById('q23_ta').value = 'IT지원팀 DBA 승인 절차';
    document.querySelector('textarea[name="q24"]').value = 'DBA 홍길동 과장';
    document.querySelector('textarea[name="q25"]').value = '최소 12자, 복잡도 강제, 180일 변경';
    setYN(26, 'Y');  // os_access
    document.querySelector('textarea[name="q27"]').value = 'Linux RHEL 8.6';
    document.querySelector('input[name="q28"][value="Y"]').checked = true;
    toggleTextInput3(28);
    document.getElementById('q28_text_input').value = 'Bastion Host';
    setYN(29, 'Y');
    document.querySelector('input[name="q30"][value="Y"]').checked = true; toggleTextarea4(30); document.getElementById('q30_ta').value = 'SA 승인 후 접속 계정 부여';
    document.querySelector('textarea[name="q31"]').value = 'SA 이순신 책임';
    document.querySelector('textarea[name="q32"]').value = '최소 12자, SSH Key 방식';
    setYN(33, 'Y');  // vpn
    applyConditions();
}

document.addEventListener('DOMContentLoaded', applyConditions);
</script>
{% endblock %}
