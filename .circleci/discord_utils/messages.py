import os

project = os.getenv('CIRCLE_PROJECT_REPONAME')
build_number = os.getenv('CIRCLE_BUILD_NUM')
def ci_failure_message():
    job_name = os.getenv('CIRCLE_JOB')
    return {
        "description": f'''Project: `{project}`\nPipeline #{build_number} Has Failed at Job `{job_name}`.''',
        "title": 'Failure',
        "url": "https://github.com/maged1995",
        "color": 0x992d22
    }

def ci_success_message():
    return {
        "description": f'''Project: `{project}`\nPipeline #{build_number} Has Succeeded''',
        "title": 'Success',
        "url": "https://github.com/maged1995",
        "color": 0x6aa84f
    }