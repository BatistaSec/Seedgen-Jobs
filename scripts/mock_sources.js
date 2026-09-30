const crypto = require('crypto');

/**
 * Script utilitário mock_sources.js
 * Serve para validar rapidamente a lógica de extração das APIs externas
 * antes de implementar no nó de Code do n8n.
 */

const mockRemotiveData = {
  id: 123456,
  url: "https://remotive.com/job/123456",
  title: "Junior Java Backend Developer",
  company_name: "Tech Corp",
  category: "Software Development",
  job_type: "full_time",
  publication_date: "2026-09-23T10:00:00Z",
  candidate_required_location: "Worldwide",
  salary: "$50k - $70k",
  description: "We are looking for a junior Java dev with Spring Boot experience...",
};

function normalizeRemotive(rawJob) {
  const normalized = {
    source: 'remotive',
    external_id: String(rawJob.id),
    title: rawJob.title,
    company: rawJob.company_name,
    location: rawJob.candidate_required_location,
    remote_type: 'Remote',
    salary: rawJob.salary,
    description: rawJob.description,
    url: rawJob.url,
    published_at: rawJob.publication_date
  };

  const hashData = normalized.source + '_' + normalized.external_id;
  normalized.hash = crypto.createHash('sha256').update(hashData).digest('hex');
  return normalized;
}

console.log("Teste de Normalização (Remotive):");
console.log(JSON.stringify(normalizeRemotive(mockRemotiveData), null, 2));
