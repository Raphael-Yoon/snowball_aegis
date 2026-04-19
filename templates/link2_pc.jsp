{% extends 'link2_base.jsp' %}

{# ================================================================
   PC 섹션 (Q34~Q40)  Program Change

   Q34: pc_can_modify  (type 1, Y/N) ← 분기점
        N → Q35~Q40 숨김
   Q35: pc01_change_history (type 1)
   Q36: pc01_procedure      (type 4)
   Q37: pc02_procedure      (type 4)
   Q38: pc03_procedure      (type 4)
   Q39: pc04_deploy_auth    (type 5)
   Q40: pc05_dev_env        (type 1)

   Cloud 조건 (공통 섹션 저장값):
   ─ SaaS → 전체 섹션 질문이 해당없음 안내 표시
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

{% block section_content %}
{% set qs = section_questions %}

{# SaaS+SOC1 안내 배너 (JS로 가시성 제어) #}
<div id="saas_soc1_banner" class="alert alert-info mb-3" style="display:none;">
    <i class="fas fa-info-circle me-2"></i>
    SaaS 환경에서는 프로그램 변경 통제가 서비스 제공업체 관할입니다.
    아래 질문들은 자동으로 해당없음 처리됩니다.
</div>

{# Q34: pc_can_modify (type 1) - 컨텍스트 파악용 (분기점 아님) #}
{% set q = qs[0] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx + 1 }}/52</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ yn_field(idx, answers) }}
    </div>
</div>

{# Q35: pc01_change_history (type 1) #}
{% set q = qs[1] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ yn_field(idx, answers) }}
    </div>
</div>

{# Q36: pc01_procedure (type 4) #}
{% set q = qs[2] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ type4_field(idx, q, answers, textarea_answers) }}
    </div>
</div>

{# Q37: pc02_procedure (type 4) #}
{% set q = qs[3] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ type4_field(idx, q, answers, textarea_answers) }}
    </div>
</div>

{# Q38: pc03_procedure (type 4) #}
{% set q = qs[4] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        {{ type4_field(idx, q, answers, textarea_answers) }}
    </div>
</div>

{# Q39: pc04_deploy_auth (type 5) #}
{% set q = qs[5] %}{% set idx = q.index %}
<div id="qblock_{{ idx }}" class="question-block card mb-3">
    <div class="card-body">
        <div class="q-num">Q{{ idx - section_info.q_start + 1 }}</div>
        <div class="q-text">{{ q.text }}</div>
        {% if q.help %}<div class="q-help mb-2">{{ q.help|safe }}</div>{% endif %}
        <textarea class="form-control" name="q{{ idx }}"
                  placeholder="{{ q.text_help or '이관 권한자 정보를 입력하세요.' }}" rows="3">{{ answers[idx] }}</textarea>
    </div>
</div>

{# Q40: pc05_dev_env (type 1) #}
{% set q = qs[6] %}{% set idx = q.index %}
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
const _cloudType = '{{ answers[Q_ID["cloud_type"]] }}';

function applyConditions() {
    const isSaaS = (_cloudType === 'SaaS');

    // SaaS: 배너 표시, Q34~Q40 전체 숨김 (분기 질문 포함)
    const banner = document.getElementById('saas_soc1_banner');
    if (banner) banner.style.display = isSaaS ? '' : 'none';

    if (isSaaS) {
        toggleRange(34, 40, false);
        return;
    }
}

function fillAllSamples() {
    setYN(34, 'Y');  // can_modify
    setYN(35, 'Y');  // change_history
    document.querySelector('input[name="q36"][value="Y"]').checked = true; toggleTextarea4(36); document.getElementById('q36_ta').value = '개발팀장 승인 후 운영 반영';
    document.querySelector('input[name="q37"][value="Y"]').checked = true; toggleTextarea4(37); document.getElementById('q37_ta').value = '사용자 테스트 확인서 작성 후 진행';
    document.querySelector('input[name="q38"][value="Y"]').checked = true; toggleTextarea4(38); document.getElementById('q38_ta').value = 'IT팀장 최종 승인 후 이관';
    document.querySelector('textarea[name="q39"]').value = '운영담당자 김철수 과장';
    setYN(40, 'Y');  // dev_env 분리
    applyConditions();
}

document.addEventListener('DOMContentLoaded', applyConditions);
</script>
{% endblock %}
