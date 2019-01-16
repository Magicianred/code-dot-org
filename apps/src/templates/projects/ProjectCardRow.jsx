import React, {PropTypes} from 'react';
import ProjectCard from './ProjectCard';

const projectProp = PropTypes.shape({
  channel: PropTypes.string.isRequired,
  thumbnailUrl: PropTypes.string.isRequired,

  name: PropTypes.string,
  publishedAt: PropTypes.date,
  studentAgeRange: PropTypes.string,
  studentName: PropTypes.string,
  type: PropTypes.string,
  updatedAt: PropTypes.date,
});

const styles = {
  card: {
    display: 'inline-block',
    paddingTop: 10,
    paddingBottom: 20,
  },
  row: {
    display: 'flex',
    justifyContent: 'space-between',
    flexWrap: 'wrap',
  },
};

export default class ProjectCardRow extends React.Component {
  static propTypes = {
    projects: PropTypes.arrayOf(projectProp).isRequired,
    galleryType: PropTypes.oneOf(['personal', 'public']).isRequired,
  };

  render() {
    return (
      <div style={styles.row}>
        {this.props.projects.map(project => (
          <div key={project.channel} style={styles.card}>
            <ProjectCard
              projectData={project}
              currentGallery={this.props.galleryType}
            />
          </div>
        ))}
      </div>
    );
  }
}
