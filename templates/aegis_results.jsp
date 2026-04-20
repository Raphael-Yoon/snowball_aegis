{% include 'navi.jsp' %}
<div style="padding-top: 70px;">
<div class="container-fluid px-4 py-4">

  <div class="d-flex justify-content-between align-items-center mb-4">
    <div>
      <h4 class="fw-bold mb-1"><i class="fas fa-chart-bar text-primary me-2"></i>모니터링 결과</h4>
      <small class="text-muted">통제별 모니터링 결과를 조회합니다.</small>
    </div>
    <a href="{{ url_for('aegis_monitor.dashboard') }}" class="btn btn-outline-secondary btn-sm">
      <i class="fas fa-arrow-left me-1"></i>대시보드
    </a>
  </div>

  <!-- 필터 -->
  <div class="card shadow-sm border-0 mb-4">
    <div class="card-body py-3">
      <form method="GET" class="row g-2 align-items-end">
        <div class="col-md-2">
          <label class="form-label small fw-semibold mb-1">기준일</label>
          <select class="form-select form-select-sm" name="run_date">
            {% for d in run_dates %}
            <option value="{{ d }}" {% if d == run_date %}selected{% endif %}>{{ d }}</option>
            {% endfor %}
          </select>
        </div>
        <div class="col-md-3">
          <label class="form-label small fw-semibold mb-1">시스템</label>
          <select class="form-select form-select-sm" name="system_id">
            <option value="">전체</option>
            {% for s in systems %}
            <option value="{{ s.system_id }}" {% if selected_system == s.system_id %}selected{% endif %}>
              {{ s.system_code }} - {{ s.system_name }}
            </option>
            {% endfor %}
          </select>
        </div>
        <div class="col-md-2">
          <label class="form-label small fw-semibold mb-1">카테고리</label>
          <select class="form-select form-select-sm" name="category">
            <option value="">전체</option>
            {% for cat, label in category_labels.items() %}
            <option value="{{ cat }}" {% if selected_category == cat %}selected{% endif %}>{{ cat }}</option>
            {% endfor %}
          </select>
        </div>
        <div class="col-md-2">
          <label class="form-label small fw-semibold mb-1">상태</label>
          <select class="form-select form-select-sm" name="status">
            <option value="">전체</option>
            <option value="PASS" {% if selected_status == 'PASS' %}selected{% endif %}>PASS</option>
            <option value="FAIL" {% if selected_status == 'FAIL' %}selected{% endif %}>FAIL</option>
            <option value="WARNING" {% if selected_status == 'WARNING' %}selected{% endif %}>WARNING</option>
            <option value="ERROR" {% if selected_status == 'ERROR' %}selected{% endif %}>ERROR</option>
          </select>
        </div>
        <div class="col-md-1">
          <button type="submit" class="btn btn-primary btn-sm w-100">
            <i class="fas fa-search"></i>
          </button>
        </div>
      </form>
    </div>
  </div>

  <!-- 결과 테이블 -->
  <div class="card shadow-sm border-0">
    <div class="card-header bg-transparent border-bottom d-flex justify-content-between align-items-center">
      <h6 class="mb-0 fw-semibold"><i class="fas fa-list me-2 text-primary"></i>결과 목록 ({{ results|length }}건)</h6>
    </div>
    <div class="card-body p-0">
      <div class="table-responsive">
        <table class="table table-hover mb-0 align-middle" style="font-size:0.88rem;">
          <thead class="table-light">
            <tr>
              <th class="ps-3">기준일</th>
              <th>시스템</th>
              <th>카테고리</th>
              <th>통제코드</th>
              <th>통제명</th>
              <th class="text-end">전체건수</th>
              <th class="text-end">예외건수</th>
              <th class="text-center">상태</th>
              <th class="text-center">실행시각</th>
              <th class="text-center">상세</th>
            </tr>
          </thead>
          <tbody>
            {% for r in results %}
            <tr>
              <td class="ps-3 text-muted">{{ r.run_date }}</td>
              <td><span class="badge bg-light text-dark border">{{ r.system_code }}</span></td>
              <td><span class="badge bg-primary">{{ r.category }}</span></td>
              <td class="fw-semibold">{{ r.control_code }}</td>
              <td>{{ r.control_name }}</td>
              <td class="text-end">{{ r.total_count }}</td>
              <td class="text-end">
                {% if r.exception_count > 0 %}
                <span class="text-danger fw-bold">{{ r.exception_count }}</span>
                {% else %}
                <span class="text-muted">0</span>
                {% endif %}
              </td>
              <td class="text-center">
                {% if r.status == 'PASS' %}
                <span class="badge bg-success">PASS</span>
                {% elif r.status == 'FAIL' %}
                <span class="badge bg-danger">FAIL</span>
                {% elif r.status == 'WARNING' %}
                <span class="badge bg-warning text-dark">WARNING</span>
                {% elif r.status == 'ERROR' %}
                <span class="badge bg-secondary">ERROR</span>
                {% else %}
                <span class="badge bg-light text-muted border">{{ r.status }}</span>
                {% endif %}
              </td>
              <td class="text-center text-muted small">{{ r.run_at or '-' }}</td>
              <td class="text-center">
                <button class="btn btn-outline-secondary btn-sm" onclick="showDetail({{ r.result_id }})">
                  <i class="fas fa-search"></i>
                </button>
              </td>
            </tr>
            {% else %}
            <tr><td colspan="10" class="text-center text-muted py-4">해당 조건의 결과가 없습니다.</td></tr>
            {% endfor %}
          </tbody>
        </table>
      </div>
    </div>
  </div>

</div>
</div>

<!-- 상세 모달 -->
<div class="modal fade" id="detailModal" tabindex="-1">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="fas fa-search me-2"></i>결과 상세</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body" id="detailBody">
        <div class="text-center py-3"><div class="spinner-border text-primary"></div></div>
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
function showDetail(resultId) {
    const modal = new bootstrap.Modal(document.getElementById('detailModal'));
    document.getElementById('detailBody').innerHTML =
        '<div class="text-center py-3"><div class="spinner-border text-primary"></div></div>';
    modal.show();

    fetch(`/api/aegis/results/${resultId}`)
    .then(r => r.json())
    .then(data => {
        if (!data.success) { document.getElementById('detailBody').innerHTML = '<p class="text-danger">로드 실패</p>'; return; }
        const r = data.result;
        let detail = {};
        try { detail = JSON.parse(r.result_detail || '{}'); } catch(e) {}
        const statusClass = r.status === 'PASS' ? 'success' : r.status === 'FAIL' ? 'danger' : r.status === 'WARNING' ? 'warning' : 'secondary';
        const rows = (detail.rows || []).slice(0, 50).map(row =>
            `<tr>${Object.values(row).map(v => `<td>${v ?? ''}</td>`).join('')}</tr>`
        ).join('');
        const headers = (detail.rows && detail.rows[0]) ?
            Object.keys(detail.rows[0]).map(k => `<th>${k}</th>`).join('') : '';

        document.getElementById('detailBody').innerHTML = `
            <div class="row g-3 mb-3">
                <div class="col-md-4"><strong>시스템</strong><br>${r.system_code} - ${r.system_name}</div>
                <div class="col-md-4"><strong>통제</strong><br>${r.control_code} - ${r.control_name}</div>
                <div class="col-md-4"><strong>상태</strong><br><span class="badge bg-${statusClass} fs-6">${r.status}</span></div>
                <div class="col-md-3"><strong>예외 건수</strong><br>${r.exception_count}건</div>
                <div class="col-md-3"><strong>전체 건수</strong><br>${r.total_count}건</div>
                <div class="col-md-3"><strong>기준일</strong><br>${r.run_date}</div>
                <div class="col-md-3"><strong>실행시각</strong><br>${r.run_at || '-'}</div>
            </div>
            ${detail.error ? `<div class="alert alert-danger"><strong>오류:</strong> ${detail.error}</div>` : ''}
            ${detail.message ? `<div class="alert alert-info">${detail.message}</div>` : ''}
            ${rows ? `
            <div class="table-responsive" style="max-height:350px;overflow-y:auto;">
                <table class="table table-sm table-bordered table-striped">
                    <thead class="table-light"><tr>${headers}</tr></thead>
                    <tbody>${rows}</tbody>
                </table>
                ${detail.truncated ? `<small class="text-muted">* 최대 50건 표시 (전체 ${r.total_count}건)</small>` : ''}
            </div>` : ''}
        `;
    });
}
</script>
