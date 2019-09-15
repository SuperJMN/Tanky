using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace TankyReloaded
{
    internal class Stage : IStage
    {
        private readonly ContentManager content;

        public Stage(ContentManager content)
        {
            this.content = content;
        }

        public ICollection<IStageObject> Objects { get; } = new List<IStageObject>();

        public void AddRelative(IStageObject subject, IStageObject origin, RelativePosition relativePosition)
        {
            if (relativePosition == RelativePosition.Right)
            {
                subject.Left = origin.Left + subject.Width;
                subject.Top = origin.Top;
            }

            if (relativePosition == RelativePosition.Left)
            {
                subject.Left = origin.Left - subject.Width;
                subject.Top = origin.Top;
            }

            Add(subject);
        }

        public void Update(GameTime gameTime)
        {
            foreach (var stageObject in Objects)
            {
                stageObject.Update(gameTime);
            }
        }

        public void Draw(SpriteBatch spriteBatch)
        {
            foreach (var stageObject in Objects)
            {
                stageObject.Draw(spriteBatch);
            }
        }

        public void Add(IStageObject stageObject)
        {
            stageObject.Stage = this;
            Objects.Add(stageObject);
            stageObject.LoadContent(content);
        }
    }
}