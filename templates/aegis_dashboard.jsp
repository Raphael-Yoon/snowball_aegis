{% include 'navi.jsp' %}
<div style="padding-top: 70px;">

<div class="container-fluid px-4 py-4">

  <!-- 헤더 -->
  <div class="d-flex justify-content-between align-items-center mb-4">
    <div>
      <h4 class="fw-bold mb-1"><i class="fas fa-shield-alt text-primary me-2"></i>모니터링 대시보드</h4>
      <small class="text-muted">기준일: <strong id="resultDateLabel">{{ result_date }}</strong></small>
    </div>
    <div class="d-flex gap-2">
      <a href="{{ url_for('aegis_monitor.results_view') }}" class="btn btn-outline-secondary btn-sm">
        <i class="fas fa-list me-1"></i>결과 상세
      </a>
      <button class="btn btn-primary btn-sm" onclick="runBatch()">
        <i class="fas fa-play me-1"></i>배치 실행
      </button>
    </div>
  </div>

  <!-- 요약 카드 -->
  <div class="row g-3 mb-4">
    {% set total = (stats.get('PASS',0) + stats.get('FAIL',0) + stats.get('WARNING',0) + stats.get('ERROR',0) + stats.get('PENDING',0)) %}
    <div class="col-6 col-md-3 col-xl">
      <div class="card text-center border-0 shadow-sm">
        <div class="card-body py-3">
          <div class="fs-2 fw-bold text-secondary">{{ total }}</div>
          <small class="text-muted">전체</small>
        </div>
      </div>
    </div>
    <div class="col-6 col-md-3 col-xl">
      <div class="card text-center border-0 shadow-sm border-start border-success border-3">
        <div class="card-body py-3">
          <div class="fs-2 fw-bold text-success">{{ stats.get('PASS', 0) }}</div>
          <small class="text-muted">PASS</small>
        </div>
      </div>
    </div>
    <div class="col-6 col-md-3 col-xl">
      <div class="card text-center border-0 shadow-sm border-start border-danger border-3">
        <div class="card-body py-3">
          <div class="fs-2 fw-bold text-danger">{{ stats.get('FAIL', 0) }}</div>
          <small class="text-muted">FAIL</small>
        </div>
      </div>
    </div>
    <div class="col-6 col-md-3 col-xl">
      <div class="card text-center border-0 shadow-sm border-start border-warning border-3">
        <div class="card-body py-3">
          <div class="fs-2 fw-bold text-warning">{{ stats.get('WARNING', 0) }}</div>
          <small class="text-muted">WARNING</small>
        </div>
      </div>
    </div>
    <div class="col-6 col-md-3 col-xl">
      <div class="card text-center border-0 shadow-sm border-start border-secondary border-3">
        <div class="card-body py-3">
          <div class="fs-2 fw-bold text-secondary">{{ stats.get('ERROR', 0) + stats.get('PENDING', 0) }}</div>
          <small class="text-muted">ERROR/미실행</small>
        </div>
      </div>
    </div>
  </div>

  <!-- 통제 × 시스템 매트릭스 -->
  {% if systems and controls %}
  <div class="card shadow-sm border-0">
    <div class="card-header bg-transparent border-bottom">
      <h6 class="mb-0 fw-semibold"><i class="fas fa-table me-2 text-primary"></i>통제 × 시스템 모니터링 현황</h6>
    </div>
    <div class="card-body p-0">
      <div class="table-responsive">
        <table class="table table-bordered table-hover mb-0 align-middle text-center" style="font-size:0.85rem;">
          <thead class="table-light">
            <tr>
              <th class="text-start ps-3" style="min-width:80px;">카테고리</th>
              <th class="text-start" style="min-width:120px;">통제코드</th>
              <th class="text-start" style="min-width:200px;">통제명</th>
              {% for sys in systems %}
              <th style="min-width:100px;">{{ sys.system_code }}</th>
              {% endfor %}
            </tr>
          </thead>
          <tbody>
            {% set ns = namespace(prev_cat='') %}
            {% for ctrl in controls %}
            <tr>
              {% if ctrl.category != ns.prev_cat %}
              <td class="fw-bold text-primary align-middle text-start ps-3">
                <span class="badge bg-primary">{{ ctrl.category }}</span>
                <div class="small text-muted mt-1" style="font-size:0.75rem;">{{ category_labels.get(ctrl.category, '') }}</div>
              </td>
              {% set ns.prev_cat = ctrl.category %}
              {% else %}
              <td></td>
              {% endif %}
              <td class="fw-semibold text-start">{{ ctrl.control_code }}</td>
              <td class="text-start">{{ ctrl.control_name }}</td>
              {% for sys in systems %}
              {% set r = result_map.get((ctrl.control_id, sys.system_id)) %}
              <td>
                {% if r %}
                  {% if r.status == 'PASS' %}
                  <span class="badge bg-success" style="cursor:pointer;" onclick="showDetail({{ r.result_id }})">
                    <i class="fas fa-check me-1"></i>PASS
                  </span>
                  {% elif r.status == 'FAIL' %}
                  <span class="badge bg-danger" style="cursor:pointer;" onclick="showDetail({{ r.result_id }})">
                    <i class="fas fa-times me-1"></i>FAIL
                    {% if r.exception_count %}<br><small>{{ r.exception_count }}건</small>{% endif %}
                  </span>
                  {% elif r.status == 'WARNING' %}
                  <span class="badge bg-warning text-dark" style="cursor:pointer;" onclick="showDetail({{ r.result_id }})">
                    <i class="fas fa-exclamation me-1"></i>WARN
                  </span>
                  {% elif r.status == 'ERROR' %}
                  <span class="badge bg-secondary" style="cursor:pointer;" onclick="showDetail({{ r.result_id }})">
                    <i class="fas fa-bug me-1"></i>ERR
                  </span>
                  {% else %}
                  <span class="badge bg-light text-muted border">-</span>
                  {% endif %}
                {% else %}
                <span class="text-muted" style="font-size:0.8rem;">-</span>
                {% endif %}
              </td>
              {% endfor %}
            </tr>
            {% endfor %}
          </tbody>
        </table>
      </div>
    </div>
  </div>
  {% else %}
  <div class="alert alert-info">
    <i class="fas fa-info-circle me-2"></i>
    등록된 시스템 또는 통제가 없습니다.
    <a href="{{ url_for('aegis_systems.systems_list') }}">시스템 등록</a> 후
    <a href="{{ url_for('aegis_controls.controls_list') }}">통제 매핑</a>을 완료해주세요.
  </div>
  {% endif %}

</div>
</div>

<!-- 상세 모달 -->
<div class="modal fade" id="detailModal" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="fas fa-search me-2"></i>모니터링 결과 상세</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body" id="detailBody">
        <div class="text-center py-3"><div class="spinner-border text-primary"></div></div>
      </div>
    </div>
  </div>
</div>

<!-- 배치 실행 결과 모달 -->
<div class="modal fade" id="batchModal" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="fas fa-play me-2"></i>배치 실행 결과</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body" id="batchBody">
        <div class="text-center py-3"><div class="spinner-border text-primary"></div><p class="mt-2">배치 실행 중...</p></div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-primary" onclick="location.reload()">새로고침</button>
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
function runBatch() {
    const modal = new bootstrap.Modal(document.getElementById('batchModal'));
    document.getElementById('batchBody').innerHTML =
        '<div class="text-center py-3"><div class="spinner-border text-primary"></div><p class="mt-2">배치 실행 중...</p></div>';
    modal.show();

    fetch('/api/aegis/run-batch', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    })
    .then(r => r.json())
    .then(data => {
        if (data.success) {
            const rows = (data.results || []).map(r => `
                <tr>
                    <td>${r.system_code}</td>
                    <td>${r.control_code}</td>
                    <td><span class="badge ${r.status==='PASS'?'bg-success':r.status==='FAIL'?'bg-danger':'bg-secondary'}">${r.status}</span></td>
                    <td class="text-end">${r.exception_count ?? '-'}</td>
                </tr>`).join('');
            document.getElementById('batchBody').innerHTML = `
                <div class="alert alert-success">${data.message}</div>
                <table class="table table-sm table-bordered">
                    <thead class="table-light"><tr><th>시스템</th><th>통제</th><th>상태</th><th class="text-end">예외건수</th></tr></thead>
                    <tbody>${rows}</tbody>
                </table>`;
        } else {
            document.getElementById('batchBody').innerHTML =
                `<div class="alert alert-danger">${data.message}</div>`;
        }
    })
    .catch(e => {
        document.getElementById('batchBody').innerHTML =
            `<div class="alert alert-danger">오류: ${e.message}</div>`;
    });
}

function showDetail(resultId) {
    const modal = new bootstrap.Modal(document.getElementById('detailModal'));
    document.getElementById('detailBody').innerHTML =
        '<div class="text-center py-3"><div class="spinner-border text-primary"></div></div>';
    modal.show();

    fetch(`/api/aegis/results/${resultId}`)
    .then(r => r.json())
    .then(data => {
        if (!data.success) { document.getElementById('detailBody').innerHTML = '<p class="text-danger">데이터 로드 실패</p>'; return; }
        const r = data.result;
        let detail = {};
        try { detail = JSON.parse(r.result_detail || '{}'); } catch(e) {}
        const statusClass = r.status === 'PASS' ? 'success' : r.status === 'FAIL' ? 'danger' : 'secondary';
        const rows = (detail.rows || []).slice(0, 20).map(row =>
            `<tr>${Object.values(row).map(v => `<td>${v ?? ''}</td>`).join('')}</tr>`
        ).join('');
        const headers = (detail.rows && detail.rows[0]) ?
            Object.keys(detail.rows[0]).map(k => `<th>${k}</th>`).join('') : '';

        document.getElementById('detailBody').innerHTML = `
            <div class="row g-3 mb-3">
                <div class="col-md-4"><strong>시스템</strong><br>${r.system_code} - ${r.system_name}</div>
                <div class="col-md-4"><strong>통제</strong><br>${r.control_code} - ${r.control_name}</div>
                <div class="col-md-4"><strong>상태</strong><br><span class="badge bg-${statusClass} fs-6">${r.status}</span></div>
                <div class="col-md-4"><strong>예외 건수</strong><br>${r.exception_count}건</div>
                <div class="col-md-4"><strong>기준일</strong><br>${r.run_date}</div>
                <div class="col-md-4"><strong>실행시각</strong><br>${r.run_at || '-'}</div>
            </div>
            ${detail.error ? `<div class="alert alert-danger">${detail.error}</div>` : ''}
            ${detail.message ? `<div class="alert alert-info">${detail.message}</div>` : ''}
            ${rows ? `
            <div class="table-responsive" style="max-height:300px;overflow-y:auto;">
                <table class="table table-sm table-bordered">
                    <thead class="table-light"><tr>${headers}</tr></thead>
                    <tbody>${rows}</tbody>
                </table>
                ${detail.truncated ? '<small class="text-muted">* 최대 20건만 표시 (전체 ' + r.total_count + '건)</small>' : ''}
            </div>` : ''}
        `;
    });
}
</script>
