{% extends 'link2_base.jsp' %}

{# ================================================================
   공통사항 섹션 (Q0~Q5)
   Q0: email          (type 2)
   Q1: system_name    (type 2)
   Q2: commercial_sw  (type 1, Y/N)
   Q3: use_cloud      (type 1, Y/N) → N이면 Q4, Q5 숨김
   Q4: cloud_type     (type 6, SaaS|PaaS|IaaS)
   Q5: soc1_report    (type 4, Y/N + textarea)
================================================================ #}

{% block section_content %}
{% set qs = section_questions %}

{# ── Q0: 이메일 ── #}
{% set q = qs[0] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx + 1 }}. 이메일</div>
        <div class="q-text">{{ q.text }}</div>
        <input type="text"
               class="form-control{% if is_logged_in %} bg-light{% endif %}"
               name="q{{ idx }}" id="q{{ idx }}"
               value="{{ answers[idx] }}"
               placeholder="{{ q.text_help or 'e-Mail 주소를 입력하세요' }}"
               required
               {% if is_logged_in %}readonly{% endif %}>
        {% if is_logged_in %}
        <small class="text-muted"><i class="fas fa-lock me-1"></i>로그인된 계정 이메일이 자동 사용됩니다.</small>
        {% endif %}
        {% if q.help %}<div class="q-help mt-2">{{ q.help|safe }}</div>{% endif %}
    </div>
</div>

{# ── Q1: 시스템명 ── #}
{% set q = qs[1] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx + 1 }}. 시스템명</div>
        <div class="q-text">{{ q.text }}</div>
        <input type="text" class="form-control" name="q{{ idx }}"
               value="{{ answers[idx] }}"
               placeholder="{{ q.text_help or '시스템명을 입력하세요' }}"
               required>
        {% if q.help %}<div class="q-help mt-2">{{ q.help|safe }}</div>{% endif %}
    </div>
</div>

{# ── Q2: 상용소프트웨어 (type 1, Y/N) ── #}
{% set q = qs[2] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx + 1 }}. 상용소프트웨어</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
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
    </div>
</div>

{# ── Q3: Cloud 사용 여부 (type 1, Y/N) → N이면 Q4·Q5 숨김 ── #}
{% set q = qs[3] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx + 1 }}. Cloud 사용 여부</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
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
    </div>
</div>

{# ── Q4: Cloud 종류 (type 6, SaaS|PaaS|IaaS) ── #}
{% set q = qs[4] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx + 1 }}. Cloud 종류</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {% for option in q.text_help.split('|') %}
        <div class="form-check mt-1">
            <input class="form-check-input" type="radio" name="q{{ idx }}"
                   value="{{ option }}" id="q{{ idx }}_{{ option }}"
                   onchange="applyConditions()"
                   {% if answers[idx] == option %}checked{% endif %}>
            <label class="form-check-label fw-semibold" for="q{{ idx }}_{{ option }}">{{ option }}</label>
        </div>
        {% endfor %}
    </div>
</div>

{# ── Q5: SOC1 Report 내부 검토 절차 (type 4, Y/N + textarea) ── #}
{% set q = qs[5] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx + 1 }}. SOC1 Report 검토</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
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
                          rows="4"
                          {% if answers[idx] == 'Y' %}required{% endif %}>{{ textarea_answers[idx] }}</textarea>
            </div>
        </div>
    </div>
</div>

{% endblock %}


{% block section_scripts %}
<script>
function applyConditions() {
    const useCloud = getVal(3);
    toggleQ(4, useCloud === 'Y');   // Cloud 종류
    toggleQ(5, useCloud === 'Y');   // SOC1 Report
}

function fillAllSamples() {
    // Q0: 이메일 (로그인 시 readonly 스킵)
    const emailEl = document.querySelector('input[name="q0"]');
    if (emailEl && !emailEl.readOnly) emailEl.value = 'snowball1566@gmail.com';
    // Q1: 시스템명
    const sysEl = document.querySelector('input[name="q1"]');
    if (sysEl) sysEl.value = '테스트 시스템';
    // Q2: 상용SW Y
    setYN(2, 'Y');
    // Q3: Cloud 사용 Y
    setYN(3, 'Y');
    // Q4: IaaS 선택
    const r4 = document.getElementById('q4_IaaS');
    if (r4) { r4.checked = true; }
    // Q5: SOC1 N
    document.querySelector('input[name="q5"][value="N"]').checked = true; toggleTextarea4(5);
    applyConditions();
}

document.addEventListener('DOMContentLoaded', applyConditions);
</script>
{% endblock %}
